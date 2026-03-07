import Foundation
import MultipeerConnectivity
import UIKit

// MARK: - Pairing MPC State

enum PairingMPCState: Equatable {
    case idle
    case advertising
    case browsing
    case connecting
    case connected
    case failed(String)

    static func == (lhs: PairingMPCState, rhs: PairingMPCState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.advertising, .advertising),
             (.browsing, .browsing), (.connecting, .connecting),
             (.connected, .connected):
            return true
        case (.failed(let l), .failed(let r)):
            return l == r
        default:
            return false
        }
    }
}

// MARK: - Pairing MPC Service

/// Lightweight MultipeerConnectivity service for direct device pairing without
/// a sphere animation or manual code entry.  Devices on the same local network
/// discover each other automatically; the user chooses which nearby device to
/// connect to and the backup data is transferred automatically.
///
/// When Bonjour advertising or browsing fails (commonly error -72008 due to
/// network restrictions or Wi-Fi not being available), the service retries a
/// configurable number of times before reporting a user-facing failure.
@MainActor
final class PairingMPCService: NSObject, ObservableObject {

    static let serviceType = "portal-pair"
    private static let transferPassword = "PortalPairTransferKey2026"

    // MARK: - Bonjour Retry Constants

    private static let netServicesErrorDomain = "NSNetServicesErrorDomain"
    private static let kNetServicesFailedCode = -72008
    private static let maxRetryCount = 5
    private static let retryDelaySeconds: Double = 3.0

    // MARK: Published State

    @Published var nearbyPeers: [MCPeerID] = []
    @Published var state: PairingMPCState = .idle
    @Published var isHost: Bool = true
    @Published var connectedPeerName: String?
    @Published var transferPhase: TransferPhase = .idle
    @Published var transferStartTime: Date?

    // MARK: Callbacks

    var onTransferComplete: ((URL) -> Void)?
    var onTransferError: ((Error) -> Void)?

    // MARK: Private

    private var peerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var receivedDataBuffer = Data()
    private var expectedTransferSize: Int64 = 0
    private var isReceivingSize = true
    private var advertisingRetryCount = 0
    private var browsingRetryCount = 0

    override init() {
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
    }

    // MARK: - Send (host / advertiser) flow

    /// Starts advertising this device so nearby receivers can discover it.
    func startAdvertising() {
        stopAll()
        isHost = true
        advertisingRetryCount = 0
        setupSession()
        beginAdvertising()
        state = .advertising
    }

    // MARK: - Receive (joiner / browser) flow

    /// Starts browsing for nearby devices that are advertising via MPC Direct.
    func startBrowsing() {
        stopAll()
        isHost = false
        browsingRetryCount = 0
        setupSession()
        beginBrowsing()
        state = .browsing
    }

    /// Invites `peer` to join the current session (receiver taps a found device).
    func connectToPeer(_ peer: MCPeerID) {
        guard let session = session else { return }
        browser?.invitePeer(peer, to: session, withContext: nil, timeout: 30)
        state = .connecting
    }

    // MARK: - Send backup data

    /// Packages the backup directory, encrypts it, and streams it to the
    /// connected peer in 512 KB chunks.
    func sendBackupData(from backupDirectory: URL) async throws {
        guard let session = session, let peer = session.connectedPeers.first else {
            throw NSError(
                domain: "PairingMPC",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: String.localized("No connected peer to send data to.")]
            )
        }

        transferPhase = .preparingData
        let payload = try BackupPayload(backupDirectory: backupDirectory)
        let encryptedData = try payload.encrypted(with: Self.transferPassword)

        // Send 8-byte size header first.
        let sizeData = withUnsafeBytes(of: Int64(encryptedData.count)) { Data($0) }
        try session.send(sizeData, toPeers: [peer], with: .reliable)

        let chunkSize = 512 * 1024
        var offset = 0
        while offset < encryptedData.count {
            if Task.isCancelled { break }
            let end = min(offset + chunkSize, encryptedData.count)
            let chunk = encryptedData.subdata(in: offset..<end)
            try session.send(chunk, toPeers: [peer], with: .reliable)
            offset = end
            let progress = Double(offset) / Double(encryptedData.count)
            transferPhase = .sending(progress: progress)
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }

    // MARK: - Cancel

    func cancel() {
        stopAll()
        state = .idle
        nearbyPeers = []
        connectedPeerName = nil
        transferPhase = .idle
        transferStartTime = nil
        advertisingRetryCount = 0
        browsingRetryCount = 0
    }

    // MARK: - Private helpers

    private func setupSession() {
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
    }

    private func beginAdvertising() {
        advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: ["mpcDirect": "1"],
            serviceType: Self.serviceType
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    private func beginBrowsing() {
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }

    private func stopAll() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        advertiser = nil
        browser = nil
        session = nil
    }

    // MARK: - Bonjour Retry Logic

    /// Retries advertising after a Bonjour failure (error -72008).
    /// Falls back to a user-friendly failure message after `maxRetryCount` attempts.
    private func retryAdvertising() {
        guard advertisingRetryCount < Self.maxRetryCount else {
            advertisingRetryCount = 0
            let msg: String = .localized(
                "Unable to start advertising. Please ensure Wi-Fi is enabled, " +
                "both devices are on the same network, and try again."
            )
            state = .failed(msg)
            return
        }
        advertisingRetryCount += 1
        Task {
            try? await Task.sleep(
                nanoseconds: UInt64(Self.retryDelaySeconds * 1_000_000_000)
            )
            advertiser?.stopAdvertisingPeer()
            advertiser = nil
            beginAdvertising()
        }
    }

    /// Retries browsing after a Bonjour failure (error -72008).
    /// Falls back to a user-friendly failure message after `maxRetryCount` attempts.
    private func retryBrowsing() {
        guard browsingRetryCount < Self.maxRetryCount else {
            browsingRetryCount = 0
            let msg: String = .localized(
                "Network discovery is unavailable. Please ensure Wi-Fi is enabled, " +
                "both devices are on the same network, and try again."
            )
            state = .failed(msg)
            return
        }
        browsingRetryCount += 1
        Task {
            try? await Task.sleep(
                nanoseconds: UInt64(Self.retryDelaySeconds * 1_000_000_000)
            )
            browser?.stopBrowsingForPeers()
            browser = nil
            beginBrowsing()
        }
    }

    // MARK: - Receive-side data processing

    private func processReceivedBackup() {
        let bufferCopy = receivedDataBuffer
        Task { @MainActor in
            do {
                let payload = try BackupPayload.decrypted(
                    from: bufferCopy,
                    password: Self.transferPassword
                )
                let tempDir = FileManager.default.temporaryDirectory
                    .appendingPathComponent("MPCPairingReceived_\(UUID().uuidString)")
                try payload.extract(to: tempDir)
                UserDefaults.standard.set(tempDir.path, forKey: "pendingNearbyBackupRestore")
                self.transferPhase = .complete(receivedURL: tempDir)
                self.onTransferComplete?(tempDir)
            } catch {
                self.transferPhase = .failed(error.localizedDescription)
                self.onTransferError?(error)
            }
        }
    }
}

// MARK: - MCSessionDelegate

extension PairingMPCService: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                self.connectedPeerName = peerID.displayName
                self.state = .connected
                self.transferStartTime = Date()
                // If this device is the host, kick off the transfer automatically.
                if self.isHost {
                    Task {
                        let backupDir = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(
                            .applicationSupportDirectory, .userDomainMask, true
                        ).first ?? "").appendingPathComponent("Backup")
                        do {
                            try await self.sendBackupData(from: backupDir)
                            self.transferPhase = .complete(receivedURL: nil)
                        } catch {
                            self.transferPhase = .failed(error.localizedDescription)
                            self.onTransferError?(error)
                        }
                    }
                }
            case .notConnected:
                if case .connected = self.state {
                    let msg: String = .localized("Connection lost. Please try again.")
                    self.state = .failed(msg)
                    self.transferPhase = .failed(msg)
                }
            default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            if self.isReceivingSize {
                guard data.count >= 8 else { return }
                self.expectedTransferSize = data.withUnsafeBytes { $0.load(as: Int64.self) }
                guard self.expectedTransferSize > 0 else { return }
                self.isReceivingSize = false
                self.receivedDataBuffer = Data()
            } else {
                self.receivedDataBuffer.append(data)
                let progress = Double(self.receivedDataBuffer.count) / Double(self.expectedTransferSize)
                self.transferPhase = .receiving(progress: min(progress, 1.0))
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

extension PairingMPCService: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor in
            invitationHandler(true, self.session)
        }
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor in
            self.retryAdvertising()
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension PairingMPCService: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            // Only show peers that are using MPC Direct (not animation-pairing peers).
            guard info?["mpcDirect"] == "1" else { return }
            if !self.nearbyPeers.contains(where: { $0 == peerID }) {
                self.nearbyPeers.append(peerID)
            }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            self.nearbyPeers.removeAll { $0 == peerID }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor in
            self.retryBrowsing()
        }
    }
}
