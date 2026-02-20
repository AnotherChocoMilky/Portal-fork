import SwiftUI
import Combine

class ColorBackgroundManager: ObservableObject {
    static let shared = ColorBackgroundManager()

    @Published var animateBackground: Bool {
        didSet {
            UserDefaults.standard.set(animateBackground, forKey: "Feather.animateBackground")
        }
    }

    @Published var bgColorHex: String {
        didSet {
            UserDefaults.standard.set(bgColorHex, forKey: UserDefaults.Keys.background)
        }
    }

    private init() {
        self.animateBackground = UserDefaults.standard.bool(forKey: "Feather.animateBackground")
        self.bgColorHex = UserDefaults.standard.string(forKey: UserDefaults.Keys.background) ?? Color.defaultBackground
    }

    func setBackgroundColor(_ color: Color) {
        if let hex = color.toHex() {
            bgColorHex = hex
        }
    }
}
