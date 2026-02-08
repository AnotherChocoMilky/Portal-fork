import SwiftUI
import NimbleViews

struct GlobalThemeModifier: ViewModifier {
    @AppStorage(UserDefaults.Keys.background) private var bgColorHex: String = Color.defaultBackground
    @AppStorage(UserDefaults.Keys.uiElement) private var uiElementColorHex: String = Color.defaultUIElement
    @AppStorage(UserDefaults.Keys.text) private var textColorHex: String = Color.defaultText

    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        var bgColor = Color(hex: bgColorHex)
        var uiColor = Color(hex: uiElementColorHex)
        var textColor = Color(hex: textColorHex)

        if colorScheme == .light {
            // User requested everything black in Light Mode
            bgColor = .black
            uiColor = .black
            textColor = .black
        }

        return content
            .foregroundStyle(textColor)
            .tint(uiColor)
            .accentColor(uiColor)
            .background(bgColor.ignoresSafeArea())
            .preferredColorScheme(colorScheme == .light ? .dark : nil) // Force dark appearance if light mode is "black"
            .toolbarColorScheme(colorScheme == .light ? .dark : nil, for: .navigationBar)
    }
}

extension View {
    func applyGlobalTheme() -> some View {
        self.modifier(GlobalThemeModifier())
    }
}
