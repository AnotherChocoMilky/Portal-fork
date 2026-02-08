import SwiftUI
import NimbleViews

struct ColorCustomizationView: View {
    @AppStorage(UserDefaults.Keys.background) private var bgColorHex: String = Color.defaultBackground
    @AppStorage(UserDefaults.Keys.uiElement) private var uiElementColorHex: String = Color.defaultUIElement
    @AppStorage(UserDefaults.Keys.text) private var textColorHex: String = Color.defaultText

    @State private var bgColor: Color = .white
    @State private var uiElementColor: Color = .blue
    @State private var textColor: Color = .black

    var body: some View {
        Form {
            Section {
                ColorPicker("Background Color", selection: $bgColor, supportsOpacity: false)
                ColorPicker("UI Elements Color", selection: $uiElementColor, supportsOpacity: false)
                ColorPicker("Text Color", selection: $textColor, supportsOpacity: false)
            } header: {
                Text("App Colors")
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

    private func resetColors() {
        bgColorHex = Color.defaultBackground
        uiElementColorHex = Color.defaultUIElement
        textColorHex = Color.defaultText
        loadColors()
    }
}
