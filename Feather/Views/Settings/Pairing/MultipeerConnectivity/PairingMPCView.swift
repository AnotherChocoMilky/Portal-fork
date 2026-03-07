import SwiftUI
import MultipeerConnectivity
import NimbleViews

// MARK: - Pairing MPC View

/// The default pairing screen using direct MultipeerConnectivity discovery —
/// no sphere animation or manual code entry required.
///
/// The user selects **Send Data** (this device shares its backup) or
/// **Receive Data** (this device accepts a backup).  Nearby devices are listed
/// automatically; tapping one initiates the connection and transfer.
///
/// This view is powered by `PairingMPCService` which handles all
/// MultipeerConnectivity logic, Bonjour retry handling, and data transfer.
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
