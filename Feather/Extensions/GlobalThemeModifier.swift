import SwiftUI
import NimbleViews

struct GlobalThemeModifier: ViewModifier {
    @AppStorage(UserDefaults.Keys.background) private var bgColorHex: String = Color.defaultBackground
    @AppStorage(UserDefaults.Keys.uiElement) private var uiElementColorHex: String = Color.defaultUIElement
    @AppStorage(UserDefaults.Keys.text) private var textColorHex: String = Color.defaultText
    @AppStorage(UserDefaults.Keys.secondaryText) private var secondaryTextColorHex: String = "#8E8E93"
    @AppStorage(UserDefaults.Keys.fontDesign) private var fontDesign: String = "default"
    @AppStorage(UserDefaults.Keys.blurOpacity) private var blurOpacity: Double = 1.0
    @AppStorage(UserDefaults.Keys.navBarColor) private var navBarColorHex: String = "#F2F2F7"
    @AppStorage(UserDefaults.Keys.tabBarColor) private var tabBarColorHex: String = "#F2F2F7"
    @AppStorage(UserDefaults.Keys.dividerColor) private var dividerColorHex: String = "#E5E5EA"
    @AppStorage(UserDefaults.Keys.sheetBackgroundColor) private var sheetBackgroundColorHex: String = "#F2F2F7"
    @AppStorage(UserDefaults.Keys.successColor) private var successColorHex: String = "#34C759"
    @AppStorage(UserDefaults.Keys.warningColor) private var warningColorHex: String = "#FF9500"
    @AppStorage(UserDefaults.Keys.errorColor) private var errorColorHex: String = "#FF3B30"
    @AppStorage(UserDefaults.Keys.glowIntensity) private var glowIntensity: Double = 10.0
    @AppStorage(UserDefaults.Keys.borderWidth) private var borderWidth: Double = 0.0
    @AppStorage(UserDefaults.Keys.cardOpacity) private var cardOpacity: Double = 1.0

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

        let navBarColor = Color(hex: navBarColorHex)
        let tabBarColor = Color(hex: tabBarColorHex)
        let sheetColor = Color(hex: sheetBackgroundColorHex)

        return content
            .foregroundStyle(textColor)
            .tint(uiColor)
            .accentColor(uiColor)
            .applyFontDesign(selectedFontDesign)
            .background(bgColor.opacity(blurOpacity).ignoresSafeArea())
            .toolbarColorScheme(isLight ? .light : .dark, for: .navigationBar)
            .applyToolbarBackground(navBarColor, for: .navigationBar)
            .applyToolbarBackground(tabBarColor, for: .tabBar)
            .environment(\.dividerColor, Color(hex: dividerColorHex))
            .environment(\.successColor, Color(hex: successColorHex))
            .environment(\.warningColor, Color(hex: warningColorHex))
            .environment(\.errorColor, Color(hex: errorColorHex))
            .environment(\.glowIntensity, glowIntensity)
            .environment(\.borderWidth, borderWidth)
            .environment(\.cardOpacity, cardOpacity)
            .sheetBackgroundColorModifier(sheetColor)
    }
}

private struct DividerColorKey: EnvironmentKey {
    static let defaultValue: Color = Color(UIColor.separator)
}

private struct SuccessColorKey: EnvironmentKey {
    static let defaultValue: Color = .green
}

private struct WarningColorKey: EnvironmentKey {
    static let defaultValue: Color = .orange
}

private struct ErrorColorKey: EnvironmentKey {
    static let defaultValue: Color = .red
}

private struct GlowIntensityKey: EnvironmentKey {
    static let defaultValue: Double = 10.0
}

private struct BorderWidthKey: EnvironmentKey {
    static let defaultValue: Double = 0.0
}

private struct CardOpacityKey: EnvironmentKey {
    static let defaultValue: Double = 1.0
}

extension EnvironmentValues {
    var dividerColor: Color {
        get { self[DividerColorKey.self] }
        set { self[DividerColorKey.self] = newValue }
    }

    var successColor: Color {
        get { self[SuccessColorKey.self] }
        set { self[SuccessColorKey.self] = newValue }
    }

    var warningColor: Color {
        get { self[WarningColorKey.self] }
        set { self[WarningColorKey.self] = newValue }
    }

    var errorColor: Color {
        get { self[ErrorColorKey.self] }
        set { self[ErrorColorKey.self] = newValue }
    }

    var glowIntensity: Double {
        get { self[GlowIntensityKey.self] }
        set { self[GlowIntensityKey.self] = newValue }
    }

    var borderWidth: Double {
        get { self[BorderWidthKey.self] }
        set { self[BorderWidthKey.self] = newValue }
    }

    var cardOpacity: Double {
        get { self[CardOpacityKey.self] }
        set { self[CardOpacityKey.self] = newValue }
    }
}

extension View {
    @ViewBuilder
    func sheetBackgroundColorModifier(_ color: Color) -> some View {
        if #available(iOS 16.4, *) {
            self.presentationBackground(color)
        } else {
            self
        }
    }
}

extension View {
    func applyGlobalTheme() -> some View {
        self.modifier(GlobalThemeModifier())
    }

    /// Conditionally applies the font design modifier if available (iOS 16.1+).
    @ViewBuilder
    func applyFontDesign(_ design: Font.Design) -> some View {
        if #available(iOS 16.1, *) {
            self.fontDesign(design)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyToolbarBackground(_ color: Color, for placement: ToolbarPlacement) -> some View {
        if #available(iOS 16.0, *) {
            self.toolbarBackground(color, for: placement)
        } else {
            self
        }
    }
}
