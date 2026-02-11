import SwiftUI
import NimbleViews

struct GlobalThemeModifier: ViewModifier {
    @AppStorage(UserDefaults.Keys.background) private var bgColorHex: String = Color.defaultBackground
    @AppStorage(UserDefaults.Keys.uiElement) private var uiElementColorHex: String = Color.defaultUIElement
    @AppStorage(UserDefaults.Keys.text) private var textColorHex: String = Color.defaultText
    @ObservedObject private var appState = AppStateManager.shared

    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        let isLight = colorScheme == .light

        // Background logic: Light mode gets system background, Dark mode gets custom or default dark
        let bgColor: Color = if appState.isSigning {
            Color(hex: bgColorHex)
        } else {
            isLight ? Color(UIColor.systemGroupedBackground) : Color(hex: bgColorHex)
        }

        // UI Elements logic
        let uiColor: Color = if appState.isSigning {
            Color(hex: uiElementColorHex)
        } else {
            isLight ? .accentColor : Color(hex: uiElementColorHex)
        }

        // Text color logic: Dark mode defaults to white if textColorHex is black
        let textColor: Color = if appState.isSigning {
            Color(hex: textColorHex)
        } else {
            if isLight {
                .primary
            } else {
                (textColorHex == Color.defaultText || textColorHex == "#000000") ? .white : Color(hex: textColorHex)
            }
        }

        return content
            .foregroundStyle(textColor)
            .tint(uiColor)
            .accentColor(uiColor)
            .background(bgColor.ignoresSafeArea())
            .toolbarColorScheme(isLight ? .light : .dark, for: .navigationBar)
    }
}

extension View {
    func applyGlobalTheme() -> some View {
        self.modifier(GlobalThemeModifier())
    }
}
