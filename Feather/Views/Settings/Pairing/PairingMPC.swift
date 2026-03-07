import SwiftUI
import MultipeerConnectivity
import NimbleViews

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
@MainActor
final class PairingMPCService: NSObject, ObservableObject {

    static let serviceType = "portal-pair"
    private static let transferPassword = "PortalPairTransferKey2026"

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

    override init() {
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
    }

    // MARK: - Send (host / advertiser) flow

    /// Starts advertising this device so nearby receivers can discover it.
    func startAdvertising() {
        stopAll()
        isHost = true
        setupSession()
        advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: ["mpcDirect": "1"],
            serviceType: Self.serviceType
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        state = .advertising
    }

    // MARK: - Receive (joiner / browser) flow

    /// Starts browsing for nearby devices that are advertising via MPC Direct.
    func startBrowsing() {
        stopAll()
        isHost = false
        setupSession()
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
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
    }

    // MARK: - Private helpers

    private func setupSession() {
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
    }

    private func stopAll() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        advertiser = nil
        browser = nil
        session = nil
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
            let msg: String = .localized("Unable to start advertising. Please ensure Wi-Fi is enabled and try again.")
            self.state = .failed(msg)
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
            let msg: String = .localized("Network discovery is unavailable. Please ensure Wi-Fi is enabled and try again.")
            self.state = .failed(msg)
        }
    }
}

// MARK: - Pairing MPC View

/// The default pairing screen using direct MultipeerConnectivity discovery —
/// no sphere animation or manual code entry required.
///
/// The user selects **Send Data** (this device shares its backup) or
/// **Receive Data** (this device accepts a backup).  Nearby devices are listed
/// automatically; tapping one initiates the connection and transfer.
struct PairingMPCView: View {

    var isEmbedded: Bool = false

    @StateObject private var service = PairingMPCService()
    @Environment(\.dismiss) private var dismiss

    @State private var showLoadingCover = false
    @State private var showSuccessCover = false
    @State private var successReceivedURL: URL?

    var body: some View {
        if isEmbedded {
            mainContent
        } else {
            NavigationStack {
                mainContent
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    iconSection
                    modeSection
                    statusSection
                    peerListSection
                    errorSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
        }
        .navigationTitle(.localized("Pair Devices"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(.localized("Cancel")) {
                    service.cancel()
                    dismiss()
                }
            }
        }
        .fullScreenCover(isPresented: $showLoadingCover) {
            LoadingPairView(
                transferPhase: service.transferPhase,
                isHost: service.isHost,
                pairedDeviceName: service.connectedPeerName,
                transferStartTime: service.transferStartTime
            )
            .preferredColorScheme(.dark)
        }
        .fullScreenCover(isPresented: $showSuccessCover) {
            SuccessfulPairView(
                receivedURL: successReceivedURL,
                deviceName: service.connectedPeerName,
                onDone: {
                    showSuccessCover = false
                    dismiss()
                }
            )
            .preferredColorScheme(.dark)
        }
        .onChange(of: service.transferPhase) { phase in
            switch phase {
            case .preparingData, .sending, .receiving:
                showSuccessCover = false
                showLoadingCover = true
            case .complete(let url):
                successReceivedURL = url
                showLoadingCover = false
                showSuccessCover = true
            case .failed:
                showLoadingCover = false
                showSuccessCover = false
            default:
                break
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(hue: 0.62, saturation: 0.15, brightness: 0.08),
                Color(hue: 0.65, saturation: 0.12, brightness: 0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Icon Section

    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hue: 0.58, saturation: 0.5, brightness: 0.4).opacity(0.25),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)

            Image(systemName: service.state == .connected
                  ? "checkmark.circle.fill"
                  : service.state == .advertising || service.state == .browsing
                    ? "antenna.radiowaves.left.and.right"
                    : "personalhotspot")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hue: 0.55, saturation: 0.7, brightness: 0.95),
                            Color(hue: 0.42, saturation: 0.6, brightness: 0.9)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(
                    color: Color(hue: 0.55, saturation: 0.7, brightness: 0.9).opacity(0.5),
                    radius: 16
                )
                .ifAvailableiOS17SymbolPulse(isActive: service.state == .advertising || service.state == .browsing)
        }
    }

    // MARK: - Mode Selection / Status Section

    @ViewBuilder
    private var modeSection: some View {
        if service.state == .idle {
            VStack(spacing: 14) {
                Text(.localized("Choose your role"))
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(.localized("Devices must be on the same Wi-Fi network."))
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    // Send Data button
                    Button {
                        service.startAdvertising()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 28))
                            Text(.localized("Send Data"))
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(hue: 0.70, saturation: 0.75, brightness: 0.85),
                                    Color(hue: 0.82, saturation: 0.65, brightness: 0.80)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Receive Data button
                    Button {
                        service.startBrowsing()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 28))
                            Text(.localized("Receive Data"))
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(hue: 0.55, saturation: 0.70, brightness: 0.80),
                                    Color(hue: 0.42, saturation: 0.65, brightness: 0.75)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
    }

    // MARK: - Status Section

    @ViewBuilder
    private var statusSection: some View {
        switch service.state {
        case .advertising:
            VStack(spacing: 8) {
                Text(.localized("Waiting for nearby device…"))
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(.localized("Make sure the other device is on the same Wi-Fi network and has \"Receive Data\" selected."))
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .padding(.top, 4)
            }

        case .browsing:
            VStack(spacing: 8) {
                Text(.localized("Looking for nearby devices…"))
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(.localized("Devices in \"Send Data\" mode will appear below."))
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)

                if service.nearbyPeers.isEmpty {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .padding(.top, 4)
                }
            }

        case .connecting:
            VStack(spacing: 8) {
                Text(.localized("Connecting…"))
                    .font(.headline)
                    .foregroundStyle(.white)
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            }

        case .connected:
            VStack(spacing: 8) {
                Text(.localized("Connected!"))
                    .font(.headline)
                    .foregroundStyle(.white)
                if let name = service.connectedPeerName {
                    Text(name)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                }
                Text(.localized("Transfer in progress…"))
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            }

        default:
            EmptyView()
        }
    }

    // MARK: - Peer List (browsing mode)

    @ViewBuilder
    private var peerListSection: some View {
        if case .browsing = service.state, !service.nearbyPeers.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(.localized("Nearby Devices"))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase)

                ForEach(service.nearbyPeers, id: \.self) { peer in
                    Button {
                        service.connectToPeer(peer)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "iphone.radiowaves.left.and.right")
                                .font(.title3)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(hue: 0.55, saturation: 0.7, brightness: 0.95),
                                            Color(hue: 0.42, saturation: 0.6, brightness: 0.9)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 36)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(peer.displayName)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.white)
                                Text(.localized("Tap to connect"))
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                        .padding(14)
                        .background(.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    // MARK: - Error Section

    @ViewBuilder
    private var errorSection: some View {
        if case .failed(let message) = service.state {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(.orange)
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.orange.opacity(0.9))
                        .multilineTextAlignment(.leading)
                }
                .padding(12)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    service.cancel()
                } label: {
                    Label(.localized("Try Again"), systemImage: "arrow.clockwise")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    PairingMPCView()
        .preferredColorScheme(.dark)
}
#endif
