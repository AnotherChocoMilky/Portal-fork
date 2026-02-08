import SwiftUI
import NimbleViews

struct GlobalThemeModifier: ViewModifier {
    @AppStorage(UserDefaults.Keys.background) private var bgColorHex: String = Color.defaultBackground
    @AppStorage(UserDefaults.Keys.uiElement) private var uiElementColorHex: String = Color.defaultUIElement
    @AppStorage(UserDefaults.Keys.text) private var textColorHex: String = Color.defaultText

    func body(content: Content) -> some View {
        let bgColor = Color(hex: bgColorHex)
        let uiColor = Color(hex: uiElementColorHex)
        let textColor = Color(hex: textColorHex)

        content
            // Apply text color to primary text
            .foregroundStyle(textColor)
            // Apply accent/UI color
            .tint(uiColor)
            .accentColor(uiColor)
            // Apply background to the whole view
            .background(bgColor.ignoresSafeArea())
    }
}

extension View {
    func applyGlobalTheme() -> some View {
        self.modifier(GlobalThemeModifier())
    }
}
