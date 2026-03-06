import SwiftUI
import NimbleViews

// MARK: - Pairing View
/// The main "Pair Devices" screen.
///
/// The pairing code is generated **automatically** the moment this view appears —
/// no button press required.  A 3D morphing-dot sphere (chaos → Fibonacci order)
/// plays throughout the session and a complex success animation (expanding rings +
/// orbiting sparkles + bounce checkmark) plays when pairing and transfer complete.
///
/// The **Scan Pairing Code** button lets the receiving device enter the code that
/// is displayed on the sending device.
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

    // Success animation state
    @State private var ringScales: [CGFloat] = [1, 1, 1, 1, 1]
    @State private var ringOpacities: [Double] = [0, 0, 0, 0, 0]
    @State private var checkmarkScale: CGFloat = 0.0
    @State private var checkmarkGlow: CGFloat = 0
    @State private var sparkleAngle: Double = 0
    @State private var sparklesVisible: Bool = false

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
                    codeSection
                    actionSection
                    transferSection
                    errorSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }

            // Full-screen success overlay (plays after transfer completes)
            if case .complete = viewModel.transferPhase {
                successFullscreenOverlay
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
        }
        .sheet(isPresented: $viewModel.showScanSheet) {
            scanSheet
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

    // MARK: - Code Section (colorful rainbow digits)

    @ViewBuilder
    private var codeSection: some View {
        if let code = viewModel.generatedCode, viewModel.isHost, viewModel.status != .idle {
            VStack(spacing: 10) {
                Text(.localized("Your Pairing Code"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    ForEach(Array(code.enumerated()), id: \.offset) { index, char in
                        colorfulDigit(String(char), index: index, total: code.count)
                    }
                }

                Text(.localized("Enter this code on the other device"))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func colorfulDigit(_ digit: String, index: Int, total: Int) -> some View {
        // Each digit gets a distinct hue cycling through the rainbow
        let hue = Double(index) / Double(max(total, 1)) * 0.82 + 0.05
        let digitColor = Color(hue: hue, saturation: 0.88, brightness: 1.0)
        return Text(digit)
            .font(.system(size: 28, weight: .bold, design: .monospaced))
            .foregroundStyle(digitColor)
            .frame(width: 42, height: 52)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(digitColor.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(digitColor.opacity(0.35), lineWidth: 1.5)
                    )
            )
            .shadow(color: digitColor.opacity(0.4), radius: 8)
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
            } else if case .connected = viewModel.status {
                if case .complete = viewModel.transferPhase {
                    Button(action: { dismiss() }) {
                        Label(.localized("Done"), systemImage: "checkmark")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.green.opacity(0.75))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
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

    // MARK: - Transfer Progress Section

    @ViewBuilder
    private var transferSection: some View {
        switch viewModel.transferPhase {
        case .preparingData:
            transferCard(
                icon: "archivebox.fill",
                label: .localized("Preparing data…"),
                progress: nil,
                color: .blue
            )
        case .sending(let p):
            transferCard(
                icon: "arrow.up.circle.fill",
                label: .localized("Sending \(Int(p * 100))%"),
                progress: p,
                color: .purple
            )
        case .receiving(let p):
            transferCard(
                icon: "arrow.down.circle.fill",
                label: .localized("Receiving \(Int(p * 100))%"),
                progress: p,
                color: .cyan
            )
        case .failed(let msg):
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
                Text(msg)
                    .font(.footnote)
                    .foregroundStyle(.orange.opacity(0.9))
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .background(Color.orange.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .transition(.move(edge: .bottom).combined(with: .opacity))
        default:
            EmptyView()
        }
    }

    private func transferCard(icon: String, label: String, progress: Double?, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                if let p = progress {
                    Text("\(Int(p * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            if let p = progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color)
                            .frame(width: geo.size.width * p, height: 4)
                            .animation(.easeInOut(duration: 0.2), value: p)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(14)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .transition(.move(edge: .bottom).combined(with: .opacity))
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

    // MARK: - Complex Success Animation (Apple Watch-style)

    private var successFullscreenOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .transition(.opacity)

            ZStack {
                // 5 staggered expanding rings with angular gradient stroke
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [.green, .cyan, .blue, .purple, .green],
                                center: .center
                            ),
                            lineWidth: max(0.5, 2.5 - Double(i) * 0.4)
                        )
                        .frame(
                            width: CGFloat(70 + i * 38),
                            height: CGFloat(70 + i * 38)
                        )
                        .scaleEffect(ringScales[i])
                        .opacity(ringOpacities[i])
                }

                // Central glow pulse
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.green.opacity(0.45), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: checkmarkGlow)

                // 8 orbiting rainbow sparkles
                if sparklesVisible {
                    ForEach(0..<8, id: \.self) { i in
                        let angle = Double(i) * 45.0 + sparkleAngle
                        let rad: Double = 92
                        let x = cos(angle * .pi / 180.0) * rad
                        let y = sin(angle * .pi / 180.0) * rad
                        let hue = Double(i) / 8.0
                        Circle()
                            .fill(Color(hue: hue, saturation: 0.9, brightness: 1.0))
                            .frame(width: 7, height: 7)
                            .offset(x: x, y: y)
                            .shadow(
                                color: Color(hue: hue, saturation: 0.9, brightness: 1.0).opacity(0.8),
                                radius: 5
                            )
                    }
                }

                // Bouncing checkmark
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(checkmarkScale)
                    .shadow(color: .green.opacity(0.7), radius: 24)

                // "Paired!" label below the checkmark
                VStack(spacing: 6) {
                    Spacer().frame(height: 90)
                    Text(.localized("Paired & Transferred!"))
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(checkmarkScale)
                    Text(.localized("Your data has been transferred successfully."))
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .scaleEffect(checkmarkScale)
                }
            }
        }
        .onAppear(perform: triggerSuccessAnimation)
        .transition(.opacity)
    }

    private func triggerSuccessAnimation() {
        HapticsManager.shared.success()

        // Set initial ring opacities to visible, then fade+expand them outward
        for i in 0..<5 {
            ringOpacities[i] = 0.85
            let delay = Double(i) * 0.14
            withAnimation(.easeOut(duration: 1.4).delay(delay)) {
                ringScales[i] = 2.2 + Double(i) * 0.25
                ringOpacities[i] = 0.0
            }
        }

        // Bounce checkmark in
        withAnimation(.spring(response: 0.45, dampingFraction: 0.50).delay(0.08)) {
            checkmarkScale = 1.0
        }

        // Glow pulse
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true).delay(0.1)) {
            checkmarkGlow = 28
        }

        // Sparkles appear and spin
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            sparklesVisible = true
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                sparkleAngle = 360
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    PairingView()
        .preferredColorScheme(.dark)
}
#endif
