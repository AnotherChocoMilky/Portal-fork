import Foundation
import MultipeerConnectivity
import UIKit

// MARK: - Pairing Service
/// Manages the device pairing session lifecycle using MultipeerConnectivity.
/// Devices discover and authenticate each other over the local network using
/// a shared 6-digit pairing code embedded in the MPC discovery info.
///
/// All mutable state is confined to the main actor; delegate callbacks hop
/// back to `@MainActor` via `Task { @MainActor in … }`.
@MainActor
final class PairingService: NSObject {

    static let shared = PairingService()
    static let serviceType = "portal-pair"

    // MARK: - Private State

    private var peerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var currentCode: String?
    private var internalStatus: PairingStatus = .idle

    private override init() {
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
    }

    // MARK: - Generate Code (Host side)

    /// Generates a random 6-digit pairing code, begins advertising over the
    /// local network, and returns the code for display on this device.
    func generatePairingCode() async throws -> String {
        let code = String(format: "%06d", Int.random(in: 0...999_999))
        currentCode = code
        internalStatus = .waiting
        setupSession()
        startAdvertising(with: code)
        return code
    }

    // MARK: - Start Pairing (Join side)

    /// Begins browsing the local network for a device advertising the given code.
    func startPairing(code: String) async throws {
        currentCode = code
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
    }

    // MARK: - Validate

    /// Returns `true` if the provided `code` is a valid 6-digit number.
    func validateCode(_ code: String) async throws -> Bool {
        return code.count == 6 && code.allSatisfy(\.isNumber)
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
    }
}

// MARK: - MCSessionDelegate

extension PairingService: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                self.internalStatus = .connected
            case .notConnected:
                if self.internalStatus == .waiting {
                    self.internalStatus = .failed("Connection lost. Please try again.")
                }
            default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {}

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
            self.internalStatus = .failed(error.localizedDescription)
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
            self.internalStatus = .failed(error.localizedDescription)
        }
    }
}
