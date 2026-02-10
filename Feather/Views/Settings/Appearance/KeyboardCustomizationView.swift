import SwiftUI
import PhotosUI

struct KeyboardCustomizationView: View {
    @StateObject private var manager = KeyboardCustomizeManager.shared

    @State private var startColor: Color = .blue
    @State private var endColor: Color = .cyan

    var body: some View {
        List {
            Section {
                Toggle(isOn: $manager.isEnabled) {
                    AppearanceRowLabel(icon: "keyboard", title: "Enable Backdrop", color: .purple)
                }
            } header: {
                AppearanceSectionHeader(title: "Status", icon: "power")
            } footer: {
                Text("When enabled, a custom dynamic background will appear behind the system keyboard. This works best with the system keyboard's natural translucency.")
            }

            if manager.isEnabled {
                Section {
                    Toggle(isOn: $manager.showAnimatedOrbs) {
                        AppearanceRowLabel(icon: "sparkles", title: "Animated Orbs", color: .blue)
                    }

                    Toggle(isOn: $manager.useGradient) {
                        AppearanceRowLabel(icon: "paintpalette", title: "Custom Gradient", color: .orange)
                    }

                    if manager.useGradient {
                        ColorPicker(selection: $startColor, supportsOpacity: false) {
                            AppearanceRowLabel(icon: "1.circle", title: "Start Color", color: .orange)
                        }
                        .onChange(of: startColor) { manager.gradientStart = $0.toHex() ?? "#0077BE" }

                        ColorPicker(selection: $endColor, supportsOpacity: false) {
                            AppearanceRowLabel(icon: "2.circle", title: "End Color", color: .orange)
                        }
                        .onChange(of: endColor) { manager.gradientEnd = $0.toHex() ?? "#00AEEF" }
                    }
                } header: {
                    AppearanceSectionHeader(title: "Background Type", icon: "square.fill")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        AppearanceRowLabel(icon: "drop", title: "Opacity: \(Int(manager.opacity * 100))%", color: .blue)
                        Slider(value: $manager.opacity, in: 0...1)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        AppearanceRowLabel(icon: "fossil.shell", title: "Blur: \(Int(manager.blurRadius))", color: .cyan)
                        Slider(value: $manager.blurRadius, in: 0...30)
                    }
                    .padding(.vertical, 4)
                } header: {
                    AppearanceSectionHeader(title: "Effects", icon: "wand.and.stars")
                }

                Section {
                    KeyboardBackdropView()
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            Text("Preview")
                                .font(.caption.bold())
                                .padding(4)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .padding(8),
                            alignment: .topLeading
                        )
                } header: {
                    AppearanceSectionHeader(title: "Preview", icon: "eye")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Keyboard Backdrop")
        .onAppear {
            startColor = Color(hex: manager.gradientStart)
            endColor = Color(hex: manager.gradientEnd)
        }
    }
}

struct KeyboardBackdropView: View {
    @ObservedObject var manager = KeyboardCustomizeManager.shared
    @State private var floatingAnimation = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Base Background
            if manager.useGradient {
                LinearGradient(
                    colors: [Color(hex: manager.gradientStart), Color(hex: manager.gradientEnd)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                Color(uiColor: .systemBackground)
            }

            // Dynamic Animated Orbs
            if manager.showAnimatedOrbs {
                GeometryReader { geo in
                    ZStack {
                        // Primary accent orb
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.accentColor.opacity(0.4),
                                        Color.accentColor.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                            .blur(radius: 40)
                            .offset(x: floatingAnimation ? -30 : 30, y: floatingAnimation ? -20 : 20)
                            .position(x: geo.size.width * 0.2, y: geo.size.height * 0.3)

                        // Secondary orb
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.purple.opacity(0.3),
                                        Color.purple.opacity(0.05),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .blur(radius: 30)
                            .offset(x: floatingAnimation ? 25 : -25, y: floatingAnimation ? 10 : -10)
                            .position(x: geo.size.width * 0.8, y: geo.size.height * 0.7)

                        // Tertiary orb
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.cyan.opacity(0.2),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                            .offset(x: floatingAnimation ? -15 : 15, y: floatingAnimation ? 20 : -20)
                            .position(x: geo.size.width * 0.5, y: geo.size.height * 0.8)
                    }
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                        floatingAnimation = true
                    }
                }
            }
        }
        .blur(radius: manager.blurRadius)
        .opacity(manager.opacity)
        .allowsHitTesting(false) // Non-interactive
    }
}

struct KeyboardBackdropModifier: ViewModifier {
    @ObservedObject var manager = KeyboardCustomizeManager.shared

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content

            if manager.isEnabled && manager.keyboardHeight > 0 {
                KeyboardBackdropView()
                    .frame(maxWidth: .infinity)
                    .frame(height: manager.keyboardHeight)
                    .transition(.move(edge: .bottom))
                    .ignoresSafeArea(.container, edges: .bottom)
                    .zIndex(999)
            }
        }
    }
}

extension View {
    func withKeyboardBackdrop() -> some View {
        self.modifier(KeyboardBackdropModifier())
    }
}
