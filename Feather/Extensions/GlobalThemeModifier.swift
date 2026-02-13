import SwiftUI
import NimbleViews

struct GlobalThemeModifier: ViewModifier {
    @AppStorage(UserDefaults.Keys.background) private var bgColorHex: String = Color.defaultBackground
    @AppStorage(UserDefaults.Keys.uiElement) private var uiElementColorHex: String = Color.defaultUIElement
    @AppStorage(UserDefaults.Keys.text) private var textColorHex: String = Color.defaultText
    @AppStorage(UserDefaults.Keys.secondaryText) private var secondaryTextColorHex: String = "#8E8E93"
    @AppStorage(UserDefaults.Keys.fontDesign) private var fontDesign: String = "default"
    @AppStorage(UserDefaults.Keys.blurOpacity) private var blurOpacity: Double = 1.0

    @ObservedObject private var appState = AppStateManager.shared

    @Environment(\.colorScheme) var colorScheme

    private var selectedFontDesign: Font.Design {
        switch fontDesign {
        case "rounded": return .rounded
        case "serif": return .serif
        case "monospaced": return .monospaced
        default: return .default
        }
    }

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
            .fontDesign(selectedFontDesign)
            .background(bgColor.opacity(blurOpacity).ignoresSafeArea())
            .toolbarColorScheme(isLight ? .light : .dark, for: .navigationBar)
    }
}

extension View {
    func applyGlobalTheme() -> some View {
        self.modifier(GlobalThemeModifier())
    }
}
