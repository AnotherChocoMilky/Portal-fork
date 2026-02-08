import SwiftUI
import NimbleViews

struct ColorTheme: Identifiable, Codable, Equatable {
    var id = UUID()
    let name: String
    let bg: String
    let ui: String
    let text: String
    let tint: String
}

struct ColorCustomizationView: View {
    @AppStorage(UserDefaults.Keys.background) private var bgColorHex: String = Color.defaultBackground
    @AppStorage(UserDefaults.Keys.uiElement) private var uiElementColorHex: String = Color.defaultUIElement
    @AppStorage(UserDefaults.Keys.text) private var textColorHex: String = Color.defaultText
    @AppStorage("Feather.userTintColor") private var tintColorHex: String = "#0077BE"
    @AppStorage("Feather.userThemes") private var userThemesData: Data = Data()

    @State private var bgColor: Color = .white
    @State private var uiElementColor: Color = .blue
    @State private var textColor: Color = .black
    @State private var tintColor: Color = .blue

    @State private var showAllThemes = false
    @State private var themeName: String = ""
    @State private var showSaveAlert = false

    private let presetThemes: [ColorTheme] = [
        ColorTheme(name: "Classic", bg: "#F2F2F7", ui: "#007AFF", text: "#000000", tint: "#007AFF"),
        ColorTheme(name: "Midnight", bg: "#1C1C1E", ui: "#0A84FF", text: "#FFFFFF", tint: "#0A84FF"),
        ColorTheme(name: "OLED Black", bg: "#000000", ui: "#30D158", text: "#FFFFFF", tint: "#30D158"),
        ColorTheme(name: "Nordic", bg: "#2E3440", ui: "#88C0D0", text: "#ECEFF4", tint: "#88C0D0"),
        ColorTheme(name: "Forest", bg: "#1B2E1D", ui: "#74C69D", text: "#D8F3DC", tint: "#74C69D"),
        ColorTheme(name: "Crimson", bg: "#1A0A0A", ui: "#FF453A", text: "#FFD6D6", tint: "#FF453A"),
        ColorTheme(name: "Vibrant", bg: "#0F172A", ui: "#F43F5E", text: "#F8FAFC", tint: "#F43F5E"),
        ColorTheme(name: "Sepia", bg: "#F4ECD8", ui: "#8B4513", text: "#433422", tint: "#8B4513"),
        ColorTheme(name: "Lavender", bg: "#F3E5F5", ui: "#9C27B0", text: "#4A148C", tint: "#9C27B0"),
        ColorTheme(name: "Ocean", bg: "#E0F7FA", ui: "#00BCD4", text: "#006064", tint: "#00BCD4"),
        ColorTheme(name: "Rose Gold", bg: "#FFF1F0", ui: "#FF85C0", text: "#5C0011", tint: "#FF85C0"),
        ColorTheme(name: "Slate", bg: "#263238", ui: "#90A4AE", text: "#ECEFF1", tint: "#90A4AE"),
        ColorTheme(name: "Mint", bg: "#E8F5E9", ui: "#4CAF50", text: "#1B5E20", tint: "#4CAF50")
    ]

    private var userThemes: [ColorTheme] {
        get {
            guard let themes = try? JSONDecoder().decode([ColorTheme].self, from: userThemesData) else { return [] }
            return themes
        }
        nonmutating set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                userThemesData = encoded
            }
        }
    }

    private var allThemes: [ColorTheme] {
        presetThemes + userThemes
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Color Themes")
                            .font(.headline)
                        Spacer()
                        if allThemes.count >= 10 {
                            Button {
                                showAllThemes = true
                            } label: {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(allThemes.prefix(allThemes.count >= 10 ? 4 : allThemes.count)) { theme in
                            ThemeCard(theme: theme) {
                                applyTheme(theme)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Presets")
            } footer: {
                Text("Select a theme or save your own below.")
            }

            Section {
                ColorPicker("Background", selection: $bgColor, supportsOpacity: false)
                ColorPicker("UI Elements", selection: $uiElementColor, supportsOpacity: false)
                ColorPicker("Text", selection: $textColor, supportsOpacity: false)
                ColorPicker("Accent", selection: $tintColor, supportsOpacity: false)
            } header: {
                Text("Custom Colors")
            }

            Section {
                Button {
                    showSaveAlert = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Save Style")
                    }
                    .frame(maxWidth: .infinity)
                    .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preview")
                        .font(.headline)

                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(bgColor)
                            .frame(height: 120)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                        VStack(spacing: 12) {
                            Text("Sample Text")
                                .foregroundColor(textColor)
                                .font(.headline)

                            HStack(spacing: 16) {
                                Capsule()
                                    .fill(uiElementColor)
                                    .frame(width: 90, height: 36)
                                    .overlay(Text("Action").foregroundColor(.white).font(.system(size: 14, weight: .bold)))

                                Circle()
                                    .fill(tintColor)
                                    .frame(width: 36, height: 36)
                                    .overlay(Image(systemName: "sparkles").foregroundColor(.white).font(.system(size: 14)))
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            } header: {
                Text("Live Preview")
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadColors()
        }
        .sheet(isPresented: $showAllThemes) {
            ThemeLibraryView(themes: allThemes) { theme in
                applyTheme(theme)
                showAllThemes = false
            }
            .presentationDetents([.medium, .large])
        }
        .alert("Save Theme", isPresented: $showSaveAlert) {
            TextField("Theme Name", text: $themeName)
            Button("Save") {
                saveStyle()
                themeName = ""
            }
            Button("Cancel", role: .cancel) {
                themeName = ""
            }
        } message: {
            Text("Enter a name for your custom theme.")
        }
        .onChange(of: bgColor) { bgColorHex = $0.toHex() ?? Color.defaultBackground }
        .onChange(of: uiElementColor) { uiElementColorHex = $0.toHex() ?? Color.defaultUIElement }
        .onChange(of: textColor) { textColorHex = $0.toHex() ?? Color.defaultText }
        .onChange(of: tintColor) { tintColorHex = $0.toHex() ?? "#0077BE" }
    }

    private func loadColors() {
        bgColor = Color(hex: bgColorHex)
        uiElementColor = Color(hex: uiElementColorHex)
        textColor = Color(hex: textColorHex)
        tintColor = Color(hex: tintColorHex)
    }

    private func applyTheme(_ theme: ColorTheme) {
        bgColorHex = theme.bg
        uiElementColorHex = theme.ui
        textColorHex = theme.text
        tintColorHex = theme.tint
        loadColors()
        HapticsManager.shared.success()
    }

    private func saveStyle() {
        let newTheme = ColorTheme(
            name: themeName.isEmpty ? "My Theme \(userThemes.count + 1)" : themeName,
            bg: bgColor.toHex() ?? Color.defaultBackground,
            ui: uiElementColor.toHex() ?? Color.defaultUIElement,
            text: textColor.toHex() ?? Color.defaultText,
            tint: tintColor.toHex() ?? "#0077BE"
        )
        var updatedThemes = userThemes
        updatedThemes.append(newTheme)
        userThemes = updatedThemes
        HapticsManager.shared.success()
    }
}

struct ThemeCard: View {
    let theme: ColorTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(hex: theme.bg))
                        .frame(height: 80)
                        .shadow(color: .black.opacity(0.1), radius: 4)

                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: theme.ui))
                                .frame(width: 14, height: 14)
                            Circle()
                                .fill(Color(hex: theme.tint))
                                .frame(width: 14, height: 14)
                        }

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: theme.text))
                            .frame(width: 40, height: 4)
                    }
                }

                Text(theme.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .padding(.leading, 4)
            }
        }
        .buttonStyle(.plain)
    }
}

struct ThemeLibraryView: View {
    @Environment(\.dismiss) var dismiss
    let themes: [ColorTheme]
    let onSelect: (ColorTheme) -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(themes) { theme in
                        ThemeCard(theme: theme) {
                            onSelect(theme)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("View Themes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}
