import SwiftUI
import NimbleViews

// MARK: - Pairing View
/// The main "Pair Devices" screen.
///
/// Shows a 3D morphing-dot sphere that animates from chaos → Fibonacci order
/// as the pairing session progresses.  A 6-digit code is displayed once
/// generated; a success state shows a checkmark and a gentle success message.
struct PairingView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PairingViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        sphereSection
                        statusSection
                        codeSection
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

    // MARK: - Sphere Section

    private var sphereSection: some View {
        ZStack {
            // Subtle glow behind the sphere
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hue: 0.58, saturation: 0.6, brightness: 0.5)
                                .opacity(0.18 + viewModel.progress * 0.14),
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

            // Success checkmark overlay
            if case .connected = viewModel.status {
                successOverlay
            }
        }
    }

    private var successOverlay: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 100, height: 100)
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.statusMessage)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .animation(.easeInOut(duration: 0.3), value: viewModel.status)

            // Progress bar
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

    // MARK: - Code Section

    @ViewBuilder
    private var codeSection: some View {
        if let code = viewModel.generatedCode, viewModel.status != .idle {
            VStack(spacing: 10) {
                Text(.localized("Your Pairing Code"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    ForEach(Array(code.enumerated()), id: \.offset) { _, char in
                        codeDigit(String(char))
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

    private func codeDigit(_ digit: String) -> some View {
        Text(digit)
            .font(.system(size: 28, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .frame(width: 42, height: 52)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(spacing: 14) {
            if viewModel.status == .idle {
                // Primary start button
                Button(action: { viewModel.startGenerating() }) {
                    Label(.localized("Generate Pairing Code"), systemImage: "qrcode")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(hue: 0.58, saturation: 0.75, brightness: 0.9),
                                    Color(hue: 0.70, saturation: 0.65, brightness: 0.85)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

            } else if case .waiting = viewModel.status {
                // Simulate connection button (for demo / testing)
                Button(action: { viewModel.confirmConnected() }) {
                    Label(.localized("Simulate Connection"), systemImage: "link.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

            } else if case .connected = viewModel.status {
                Button(action: { dismiss() }) {
                    Label(.localized("Done"), systemImage: "checkmark")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.green.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            // Retry button shown after failure
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
        if let errorMessage = viewModel.errorMessage,
           case .failed = viewModel.status {
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
}

// MARK: - Preview

#if DEBUG
#Preview {
    PairingView()
        .preferredColorScheme(.dark)
}
#endif
