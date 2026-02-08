import SwiftUI
import NimbleViews

struct ColorCustomizationView: View {
    @AppStorage(UserDefaults.Keys.background) private var bgColorHex: String = Color.defaultBackground
    @AppStorage(UserDefaults.Keys.uiElement) private var uiElementColorHex: String = Color.defaultUIElement
    @AppStorage(UserDefaults.Keys.text) private var textColorHex: String = Color.defaultText

    @State private var bgColor: Color = .white
    @State private var uiElementColor: Color = .blue
    @State private var textColor: Color = .black

    private let colorThemes: [ColorTheme] = [
        ColorTheme(name: "Classic", bg: "#F2F2F7", ui: "#007AFF", text: "#000000"),
        ColorTheme(name: "Midnight", bg: "#1C1C1E", ui: "#0A84FF", text: "#FFFFFF"),
        ColorTheme(name: "OLED Black", bg: "#000000", ui: "#30D158", text: "#FFFFFF"),
        ColorTheme(name: "Nordic", bg: "#2E3440", ui: "#88C0D0", text: "#ECEFF4"),
        ColorTheme(name: "Forest", bg: "#1B2E1D", ui: "#74C69D", text: "#D8F3DC"),
        ColorTheme(name: "Crimson", bg: "#1A0A0A", ui: "#FF453A", text: "#FFD6D6"),
        ColorTheme(name: "Vibrant", bg: "#0F172A", ui: "#F43F5E", text: "#F8FAFC"),
        ColorTheme(name: "Sepia", bg: "#F4ECD8", ui: "#8B4513", text: "#433422")
    ]

    var body: some View {
        Form {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(colorThemes) { theme in
                            Button {
                                applyTheme(theme)
                            } label: {
                                VStack(spacing: 8) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(hex: theme.bg))
                                            .frame(width: 80, height: 60)
                                            .shadow(radius: 2)

                                        VStack(spacing: 4) {
                                            Circle()
                                                .fill(Color(hex: theme.ui))
                                                .frame(width: 12, height: 12)

                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color(hex: theme.text))
                                                .frame(width: 30, height: 4)
                                        }
                                    }

                                    Text(theme.name)
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            } header: {
                Text("Color Themes")
            } footer: {
                Text("Select a preset theme or customize individual colors below.")
            }

            Section {
                ColorPicker("Background Color", selection: $bgColor, supportsOpacity: false)
                ColorPicker("UI Elements Color", selection: $uiElementColor, supportsOpacity: false)
                ColorPicker("Text Color", selection: $textColor, supportsOpacity: false)
            } header: {
                Text("Custom Colors")
            } footer: {
                Text("Customize the colors used throughout the app. Changes are applied globally.")
            }

            Section {
                Button(role: .destructive) {
                    resetColors()
                } label: {
                    Text("Reset to Defaults")
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preview")
                        .font(.headline)

                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(bgColor)
                            .frame(height: 100)

                        VStack(spacing: 8) {
                            Text("Sample Text")
                                .foregroundColor(textColor)
                                .font(.headline)

                            HStack {
                                Capsule()
                                    .fill(uiElementColor)
                                    .frame(width: 80, height: 30)
                                    .overlay(Text("Button").foregroundColor(.white).font(.caption))

                                Circle()
                                    .fill(uiElementColor)
                                    .frame(width: 30, height: 30)
                                    .overlay(Image(systemName: "star.fill").foregroundColor(.white).font(.caption))
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            } header: {
                Text("Preview")
            }
        }
        .navigationTitle("Color Customization")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadColors()
        }
        .onChange(of: bgColor) { newValue in
            bgColorHex = newValue.toHex() ?? Color.defaultBackground
        }
        .onChange(of: uiElementColor) { newValue in
            uiElementColorHex = newValue.toHex() ?? Color.defaultUIElement
        }
        .onChange(of: textColor) { newValue in
            textColorHex = newValue.toHex() ?? Color.defaultText
        }
    }

    private func loadColors() {
        bgColor = Color(hex: bgColorHex)
        uiElementColor = Color(hex: uiElementColorHex)
        textColor = Color(hex: textColorHex)
    }

    private func applyTheme(_ theme: ColorTheme) {
        bgColorHex = theme.bg
        uiElementColorHex = theme.ui
        textColorHex = theme.text
        loadColors()
        HapticsManager.shared.success()
    }

    private func resetColors() {
        bgColorHex = Color.defaultBackground
        uiElementColorHex = Color.defaultUIElement
        textColorHex = Color.defaultText
        loadColors()
    }
}

struct ColorTheme: Identifiable {
    let id = UUID()
    let name: String
    let bg: String
    let ui: String
    let text: String
}
