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
