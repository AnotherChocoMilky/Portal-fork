import SwiftUI

// MARK: - Pair Code Scanner View
/// A manual code-entry view that accepts the 6-digit pairing code
/// displayed on the sender's device.
///
/// The sender's `PairingView` shows an animated 6-digit code on the sphere.
/// The user on the receiving device opens this view and types the code they
/// see on the sender's screen.  `onCodeDetected` fires automatically the
/// moment the sixth digit is entered.
struct PairCodeScannerView: View {

    // MARK: - Input

    /// Called exactly once on the main thread with a valid, parsed pairing code.
    let onCodeDetected: (String) -> Void

    // MARK: - State

    @State private var enteredCode: String = ""
    @FocusState private var isInputFocused: Bool

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            // Hidden text field that captures keyboard input.
            // Positioned off-screen so the custom digit boxes are the visible UI.
            TextField("", text: $enteredCode)
                .keyboardType(.numberPad)
                .focused($isInputFocused)
                .opacity(0)
                .frame(width: 1, height: 1)
                .onChange(of: enteredCode) { value in
                    let filtered = String(value.filter(\.isNumber).prefix(6))
                    if filtered != value { enteredCode = filtered }
                    if filtered.count == 6 {
                        isInputFocused = false
                        onCodeDetected(filtered)
                    }
                }

            VStack(spacing: 36) {
                Spacer()
                headerSection
                digitInputSection
                hintLabel
                Spacer()
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            // Give the view a moment to settle before popping the keyboard.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isInputFocused = true
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

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.cyan.opacity(0.22), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 55
                        )
                    )
                    .frame(width: 110, height: 110)

                Image(systemName: "number.square.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text(.localized("Enter Pairing Code"))
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text(.localized("Enter the 6-digit code shown on the other device."))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Digit Input

    private var digitInputSection: some View {
        let chars = Array(enteredCode)
        return HStack(spacing: 10) {
            ForEach(0..<6, id: \.self) { index in
                digitBox(at: index, char: index < chars.count ? String(chars[index]) : nil)
            }
        }
        .onTapGesture { isInputFocused = true }
    }

    private func digitBox(at index: Int, char: String?) -> some View {
        let isFilled = char != nil
        let isActive = index == enteredCode.count && isInputFocused

        return ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(isFilled
                    ? Color(hue: 0.62, saturation: 0.3, brightness: 0.22)
                    : Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isActive
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [.cyan, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing))
                                : AnyShapeStyle(Color.white.opacity(isFilled ? 0.3 : 0.15)),
                            lineWidth: isActive ? 2 : 1
                        )
                )
                .frame(width: 46, height: 56)

            if let char {
                Text(char)
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .transition(.scale.combined(with: .opacity))
            } else if isActive {
                BlinkingCursor()
            }
        }
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: enteredCode.count)
    }

    // MARK: - Hint

    @ViewBuilder
    private var hintLabel: some View {
        if enteredCode.isEmpty {
            Text(.localized("Tap the boxes to begin typing"))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
                .transition(.opacity)
                .animation(.easeInOut, value: enteredCode.isEmpty)
        }
    }
}

// MARK: - Blinking Cursor

/// A simple blinking vertical bar shown in the active digit box.
private struct BlinkingCursor: View {
    @State private var visible = true

    var body: some View {
        Rectangle()
            .fill(Color.cyan)
            .frame(width: 2, height: 28)
            .opacity(visible ? 1 : 0)
            .animation(
                .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                value: visible
            )
            .onAppear { visible = false }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    PairCodeScannerView { code in
        print("Detected pairing code: \(code)")
    }
    .preferredColorScheme(.dark)
}
#endif
