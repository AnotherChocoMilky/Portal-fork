import SwiftUI

// MARK: - iOS 17 Symbol Effect Compatibility Modifiers
struct BounceEffectModifier: ViewModifier {
    let trigger: Bool

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.symbolEffect(.bounce, value: trigger)
        } else {
            content
        }
    }
}

struct PulseEffectModifier: ViewModifier {
    let trigger: Bool

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.symbolEffect(.pulse, options: .repeating, value: trigger)
        } else {
            content
                .opacity(trigger ? 1.0 : 0.8)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: trigger)
        }
    }
}

extension View {
    func bounceEffect(_ trigger: Bool) -> some View {
        self.modifier(BounceEffectModifier(trigger: trigger))
    }

    func pulseEffect(_ trigger: Bool) -> some View {
        self.modifier(PulseEffectModifier(trigger: trigger))
    }
}

