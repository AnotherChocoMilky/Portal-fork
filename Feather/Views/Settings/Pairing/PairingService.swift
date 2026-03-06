import Foundation
import MultipeerConnectivity
import UIKit

// MARK: - Pairing Service
/// Manages the device pairing session lifecycle AND full backup data transfer
/// using MultipeerConnectivity.  Devices discover each other over the local
/// network via a shared 6-digit pairing code embedded in the MPC discovery info.
///
/// The device that generates the code is the **host** (sender); the device
/// that enters the code is the **joiner** (receiver).  After a successful
/// connection the host automatically transfers all backup data to the joiner.
///
/// All mutable state is confined to the main actor; delegate callbacks hop
/// back to `@MainActor` via `Task { @MainActor in … }`.
@MainActor
final class PairingService: NSObject {

    static let shared = PairingService()
    static let serviceType = "portal-pair"

    // MARK: - NSNetServicesErrorDomain -72008 Fallback Constants
    // This error occurs when Bonjour cannot advertise (e.g. network restrictions,
    // service name collision). We retry up to `maxRetryCount` times with a short
    // delay before surfacing a user-friendly message.
    private static let netServicesErrorDomain = "NSNetServicesErrorDomain"
    private static let kNetServicesFailedCode = -72008
    private static let maxRetryCount = 3
    private static let retryDelaySeconds: Double = 2.0

    // MARK: - Private State

    private var peerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var currentCode: String?
    private(set) var internalStatus: PairingStatus = .idle
    private var advertisingRetryCount = 0

    /// `true` when this device generated the pairing code (it will send data).
    private(set) var isHost: Bool = false
    /// The connected remote peer once a session is established.
    private(set) var connectedPeer: MCPeerID?

    // MARK: - Data Transfer State

    private var receivedDataBuffer = Data()
    private var expectedTransferSize: Int64 = 0
    private var isReceivingSize = true
    private let transferPassword = "PortalPairTransferKey2026"

    // MARK: - Callbacks

    var onStatusChanged: ((PairingStatus) -> Void)?
    var onTransferProgress: ((Double) -> Void)?
    var onTransferComplete: ((URL) -> Void)?
    var onTransferError: ((Error) -> Void)?

    private override init() {
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
    }

    // MARK: - Generate Code (Host / Sender side)

    /// Generates a random 6-digit pairing code, begins advertising over the
    /// local network, and returns the code for display on this device.
    func generatePairingCode() async throws -> String {
        let code = String(format: "%06d", Int.random(in: 0...999_999))
        currentCode = code
        isHost = true
        internalStatus = .waiting
        advertisingRetryCount = 0
        setupSession()
        startAdvertising(with: code)
        return code
    }

    // MARK: - Start Pairing (Joiner / Receiver side)

    /// Begins browsing the local network for a device advertising the given code.
    func startPairing(code: String) async throws {
        currentCode = code
        isHost = false
        internalStatus = .waiting
        setupSession()
        startBrowsing(for: code)
    }

    // MARK: - Poll Status

    /// Returns the current pairing status.
    func checkStatus(code: String) async throws -> PairingStatus {
        return internalStatus
    }

    // MARK: - Cancel

    /// Stops any in-progress pairing session and tears down local network resources.
    func cancelPairing() async {
        stop()
        internalStatus = .idle
        currentCode = nil
        advertisingRetryCount = 0
        isHost = false
    }

    // MARK: - Validate

    /// Returns `true` if the provided `code` is a valid 6-digit number.
    func validateCode(_ code: String) async throws -> Bool {
        return code.count == 6 && code.allSatisfy(\.isNumber)
    }

    // MARK: - Send Backup Data

    /// Packages the given backup directory, encrypts it, and streams it to
    /// the connected peer in chunks.  `onTransferProgress` is called with
    /// values from 0…1 as data is sent.
    func sendBackupData(from backupDirectory: URL) async throws {
        guard let peer = connectedPeer, let session = session else {
            throw NSError(
                domain: "PairingService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: String.localized("No connected peer to send data to.")]
            )
        }

        let payload = try BackupPayload(backupDirectory: backupDirectory)
        let encryptedData = try payload.encrypted(with: transferPassword)

        // Send an 8-byte size header so the receiver knows when all data has arrived.
        let sizeData = withUnsafeBytes(of: Int64(encryptedData.count)) { Data($0) }
        try session.send(sizeData, toPeers: [peer], with: .reliable)

        // Stream data in 512 KB chunks to avoid overwhelming the MPC buffers.
        let chunkSize = 512 * 1024
        var offset = 0
        while offset < encryptedData.count {
            if Task.isCancelled { break }
            let end = min(offset + chunkSize, encryptedData.count)
            let chunk = encryptedData.subdata(in: offset..<end)
            try session.send(chunk, toPeers: [peer], with: .reliable)
            offset = end
            onTransferProgress?(Double(offset) / Double(encryptedData.count))
            try? await Task.sleep(nanoseconds: 5_000_000) // 5 ms pacing
        }
    }

    // MARK: - Private Setup

    private func setupSession() {
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
    }

    private func startAdvertising(with code: String) {
        let discoveryInfo: [String: String] = [
            "code": code,
            "timestamp": "\(Date().timeIntervalSince1970)"
        ]
        advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: discoveryInfo,
            serviceType: Self.serviceType
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    private func startBrowsing(for code: String) {
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }

    private func stop() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        advertiser = nil
        browser = nil
        session = nil
        connectedPeer = nil
    }

    // MARK: - NSNetServicesErrorDomain -72008 Fallback

    /// Retries advertising after a Bonjour failure (error -72008).
    /// Falls back to a user-friendly failure message after `maxRetryCount` attempts.
    private func retryAdvertising() {
        guard advertisingRetryCount < Self.maxRetryCount, let code = currentCode else {
            let msg: String = .localized(
                "Unable to start device discovery. Please ensure Wi-Fi is enabled, " +
                "both devices are on the same network, and try again."
            )
            internalStatus = .failed(msg)
            onStatusChanged?(.failed(msg))
            return
        }
        advertisingRetryCount += 1
        Task {
            try? await Task.sleep(
                nanoseconds: UInt64(Self.retryDelaySeconds * 1_000_000_000)
            )
            advertiser?.stopAdvertisingPeer()
            advertiser = nil
            startAdvertising(with: code)
        }
    }

    // MARK: - Receive Data Processing

    private func processReceivedBackup() {
        let bufferCopy = receivedDataBuffer
        Task { @MainActor in
            do {
                let payload = try BackupPayload.decrypted(
                    from: bufferCopy,
                    password: self.transferPassword
                )
                let tempDir = FileManager.default.temporaryDirectory
                    .appendingPathComponent("PairingReceived_\(UUID().uuidString)")
                try payload.extract(to: tempDir)
                UserDefaults.standard.set(tempDir.path, forKey: "pendingNearbyBackupRestore")
                self.onTransferComplete?(tempDir)
            } catch {
                self.onTransferError?(error)
            }
        }
    }
}

// MARK: - MCSessionDelegate

extension PairingService: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                self.connectedPeer = peerID
                self.internalStatus = .connected
                self.onStatusChanged?(.connected)
            case .notConnected:
                if self.internalStatus == .waiting {
                    let msg: String = .localized("Connection lost. Please try again.")
                    self.internalStatus = .failed(msg)
                    self.onStatusChanged?(.failed(msg))
                }
            default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            if self.isReceivingSize {
                // The first 8 bytes carry the total encrypted payload size.
                guard data.count >= 8 else { return }
                self.expectedTransferSize = data.withUnsafeBytes { $0.load(as: Int64.self) }
                guard self.expectedTransferSize > 0 else { return }
                self.isReceivingSize = false
                self.receivedDataBuffer = Data()
            } else {
                self.receivedDataBuffer.append(data)
                let progress = Double(self.receivedDataBuffer.count) / Double(self.expectedTransferSize)
                self.onTransferProgress?(min(progress, 1.0))
                if self.receivedDataBuffer.count >= self.expectedTransferSize {
                    self.processReceivedBackup()
                }
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}

    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension PairingService: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor in
            invitationHandler(true, self.session)
        }
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor in
            let nsError = error as NSError
            // Fallback for NSNetServicesErrorDomain error -72008 (Bonjour advertising
            // failure, commonly caused by network restrictions or service collisions).
            if nsError.domain == Self.netServicesErrorDomain
                && nsError.code == Self.kNetServicesFailedCode {
                self.retryAdvertising()
            } else {
                self.internalStatus = .failed(error.localizedDescription)
                self.onStatusChanged?(.failed(error.localizedDescription))
            }
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension PairingService: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            guard let code = info?["code"], code == self.currentCode, let session = self.session else { return }
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor in
            let nsError = error as NSError
            // Fallback for NSNetServicesErrorDomain error -72008.
            if nsError.domain == Self.netServicesErrorDomain
                && nsError.code == Self.kNetServicesFailedCode {
                let msg: String = .localized(
                    "Network discovery is unavailable. Please ensure Wi-Fi is enabled, " +
                    "both devices are on the same network, and try again."
                )
                self.internalStatus = .failed(msg)
                self.onStatusChanged?(.failed(msg))
            } else {
                self.internalStatus = .failed(error.localizedDescription)
                self.onStatusChanged?(.failed(error.localizedDescription))
            }
        }
    }
}
