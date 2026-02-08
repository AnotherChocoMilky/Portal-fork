import SwiftUI
import NimbleViews

struct GlobalThemeModifier: ViewModifier {
    @AppStorage(UserDefaults.Keys.background) private var bgColorHex: String = Color.defaultBackground
    @AppStorage(UserDefaults.Keys.uiElement) private var uiElementColorHex: String = Color.defaultUIElement
    @AppStorage(UserDefaults.Keys.text) private var textColorHex: String = Color.defaultText
    @ObservedObject private var appState = AppStateManager.shared

    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        let bgColor = appState.isSigning ? Color(hex: bgColorHex) : (colorScheme == .light ? .black : Color(hex: bgColorHex))
        let uiColor = appState.isSigning ? Color(hex: uiElementColorHex) : (colorScheme == .light ? .black : Color(hex: uiElementColorHex))
        let textColor = appState.isSigning ? Color(hex: textColorHex) : (colorScheme == .light ? .black : Color(hex: textColorHex))

        return content
            .foregroundStyle(textColor)
            .tint(uiColor)
            .accentColor(uiColor)
            .background(bgColor.ignoresSafeArea())
            .toolbarColorScheme(colorScheme == .light ? .dark : nil, for: .navigationBar)
    }
}

extension View {
    func applyGlobalTheme() -> some View {
        self.modifier(GlobalThemeModifier())
    }
}
