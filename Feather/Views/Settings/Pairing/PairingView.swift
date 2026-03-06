import SwiftUI
import NimbleViews

// MARK: - Pairing View
/// The main "Pair Devices" screen.
///
/// The pairing code is generated **automatically** the moment this view appears —
/// no button press required.  A 3D morphing-dot sphere (chaos → Fibonacci order)
/// plays throughout the session.
///
/// Pairing happens **only** via the pairing code: the user on the other device
/// taps **Scan Pairing Code** and enters the 6-digit code shown on the sending
/// device's `LoadingPairView` header.
///
/// - `LoadingPairView` is shown on both devices as soon as the transfer starts.
/// - `SuccessfulPairView` is shown when the transfer completes.
/// - `PairHistoryView` is reachable via the toolbar History button.
///
/// When `isEmbedded` is `true` the view skips its own `NavigationStack` wrapper
/// and relies on the parent navigation context (e.g. a `NavigationLink`).
struct PairingView: View {

    // MARK: - Parameters

    /// Pass `true` when this view is pushed via a `NavigationLink` so that it
    /// doesn't add a redundant `NavigationStack`.
    var isEmbedded: Bool = false

    // MARK: - State

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PairingViewModel()

    // Full-screen cover flags
    @State private var showLoadingCover: Bool = false
    @State private var showSuccessCover: Bool = false
    @State private var successReceivedURL: URL? = nil
    @State private var showHistory: Bool = false

    // Scan sheet
    @State private var scanInput: String = ""
    @FocusState private var isScanInputFocused: Bool

    // MARK: - Body

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
            backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    sphereSection
                    statusSection
                    actionSection
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
                    viewModel.cancel()
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
            }
        }
        .sheet(isPresented: $viewModel.showScanSheet) {
            scanSheet
        }
        .sheet(isPresented: $showHistory) {
            NavigationStack {
                PairHistoryView()
            }
        }
        .fullScreenCover(isPresented: $showLoadingCover) {
            LoadingPairView(
                transferPhase: viewModel.transferPhase,
                isHost: viewModel.isHost,
                pairedDeviceName: viewModel.pairedDeviceName,
                transferStartTime: viewModel.transferStartTime
            )
            .preferredColorScheme(.dark)
        }
        .fullScreenCover(isPresented: $showSuccessCover) {
            SuccessfulPairView(
                receivedURL: successReceivedURL,
                deviceName: viewModel.pairedDeviceName,
                onDone: {
                    showSuccessCover = false
                    dismiss()
                }
            )
            .preferredColorScheme(.dark)
        }
        .onChange(of: viewModel.transferPhase) { phase in
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
        .onAppear {
            viewModel.autoStart()
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

    // MARK: - Sphere Section

    private var sphereSection: some View {
        ZStack {
            // Glow halo behind the sphere — intensifies as morphProgress grows
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hue: 0.58, saturation: 0.6, brightness: 0.5)
                                .opacity(0.18 + viewModel.progress * 0.18),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 160
                    )
                )
                .frame(width: 300, height: 300)

            PairingCodeSphere(
                morphProgress: viewModel.progress,
                pairingStatus: viewModel.status
            )
            .frame(width: 280, height: 280)
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.statusMessage)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .animation(.easeInOut(duration: 0.3), value: viewModel.statusMessage)

            // Gradient progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 5)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hue: 0.55, saturation: 0.8, brightness: 0.9),
                                    Color(hue: 0.42, saturation: 0.7, brightness: 0.85)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * viewModel.progress,
                            height: 5
                        )
                        .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
                }
            }
            .frame(maxWidth: 240, minHeight: 5, maxHeight: 5)
        }
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(spacing: 14) {
            // "Scan Pairing Code" — the main CTA on both idle AND waiting states.
            // When idle, auto-start hasn't fired yet (brief window);
            // always show it so the receiver can enter the sender's code.
            if viewModel.status == .idle || viewModel.status == .waiting || viewModel.status == .generating {
                Button(action: { viewModel.showScanSheet = true }) {
                    Label(.localized("Scan Pairing Code"), systemImage: "qrcode.viewfinder")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(hue: 0.70, saturation: 0.75, brightness: 0.90),
                                    Color(hue: 0.82, saturation: 0.65, brightness: 0.85)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            if viewModel.canRetry {
                Button(action: { viewModel.retry() }) {
                    Label(.localized("Try Again"), systemImage: "arrow.clockwise")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.status)
    }

    // MARK: - Error Section

    @ViewBuilder
    private var errorSection: some View {
        if let errorMessage = viewModel.errorMessage, case .failed = viewModel.status {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle")
                    .foregroundStyle(.orange)
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.orange.opacity(0.9))
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .background(Color.orange.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Scan Pairing Code Sheet

    private var scanSheet: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(.top, 24)

                    Text(.localized("Enter Pairing Code"))
                        .font(.title2.bold())

                    Text(.localized("Enter the 6-digit code displayed on the other device."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Colorful digit input
                HStack(spacing: 8) {
                    ForEach(0..<6, id: \.self) { i in
                        let filled = i < scanInput.count
                        let char = filled ? scanInputCharacter(at: i) : " "
                        let hue = Double(i) / 6.0 * 0.82 + 0.05
                        let col = Color(hue: hue, saturation: 0.88, brightness: 1.0)
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(filled ? col.opacity(0.15) : Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(filled ? col.opacity(0.5) : Color.white.opacity(0.15), lineWidth: 1.5)
                                )
                                .frame(width: 44, height: 56)
                            Text(char)
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundStyle(filled ? col : Color.white.opacity(0.2))
                        }
                    }
                }

                // Hidden text field for input
                TextField("", text: $scanInput)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($isScanInputFocused)
                    .opacity(0)
                    .frame(width: 1, height: 1)
                    .onChange(of: scanInput) { newVal in
                        let filtered = newVal.filter { $0.isNumber }
                        scanInput = String(filtered.prefix(6))
                    }

                // Tap anywhere on digits to focus
                Button(action: { isScanInputFocused = true }) {
                    Text(.localized("Tap to type"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button(action: connectWithScannedCode) {
                    Text(.localized("Connect"))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(scanInput.count == 6
                            ? LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [.gray, .gray], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 24)
                }
                .disabled(scanInput.count != 6)

                Spacer()
            }
            .navigationTitle(.localized("Scan Pairing Code"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        viewModel.showScanSheet = false
                    }
                }
            }
            .onAppear { isScanInputFocused = true }
        }
    }

    private func connectWithScannedCode() {
        viewModel.showScanSheet = false
        viewModel.scanCodeInput = scanInput
        viewModel.startPairing(with: scanInput)
    }

    /// Safely returns the character at position `index` in `scanInput` as a String.
    private func scanInputCharacter(at index: Int) -> String {
        guard index < scanInput.count else { return " " }
        return String(scanInput[scanInput.index(scanInput.startIndex, offsetBy: index)])
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    PairingView()
        .preferredColorScheme(.dark)
}
#endif
