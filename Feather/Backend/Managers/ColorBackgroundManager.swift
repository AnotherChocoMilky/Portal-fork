import SwiftUI
import Combine

class ColorBackgroundManager: ObservableObject {
    static let shared = ColorBackgroundManager()

    @AppStorage("Feather.appearance.baseColorData") private var baseColorData: Data = Data()

    @Published var baseColor: Color = Color(hex: Color.defaultBackground) {
        didSet {
            saveBaseColor()
        }
    }

    private init() {
        loadBaseColor()
    }

    private func loadBaseColor() {
        if let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: baseColorData) {
            baseColor = Color(uiColor)
        } else {
            baseColor = Color(hex: Color.defaultBackground)
        }
    }

    private func saveBaseColor() {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: UIColor(baseColor), requiringSecureCoding: true)
            baseColorData = data
        } catch {
            print("Failed to save base color: \(error)")
        }
    }

    func resolvedColor(for colorScheme: ColorScheme) -> Color {
        let uiColor = UIColor(baseColor)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

        if colorScheme == .light {
            // Light mode: lighter (reduce saturation, lower opacity 0.20 to 0.30)
            return Color(hue: Double(h), saturation: Double(s) * 0.4, brightness: Double(b), opacity: 0.25)
        } else {
            // Dark mode: darker, richer (increase opacity 0.55 to 0.70, slightly reduce brightness)
            return Color(hue: Double(h), saturation: Double(s), brightness: Double(b) * 0.8, opacity: 0.65)
        }
    }
}
