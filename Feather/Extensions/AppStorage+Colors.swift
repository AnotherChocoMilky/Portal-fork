import SwiftUI

extension Color {
    static let defaultBackground = "#F2F2F7"
    static let defaultUIElement = "#007AFF"
    static let defaultText = "#000000"
}

extension UserDefaults {
    public enum Keys {
        static let background = "Feather.appearance.background"
        static let uiElement = "Feather.appearance.uiElement"
        static let text = "Feather.appearance.text"
        static let secondaryText = "Feather.appearance.secondaryText"
        static let cardCornerRadius = "Feather.appearance.cardCornerRadius"
        static let buttonCornerRadius = "Feather.appearance.buttonCornerRadius"
        static let fontDesign = "Feather.appearance.fontDesign"
        static let shadowIntensity = "Feather.appearance.shadowIntensity"
        static let blurOpacity = "Feather.appearance.blurOpacity"
        static let installTrigger = "Feather.installTrigger"
    }
}
