import SwiftUI
import Combine

enum EasterEggEffect: String, CaseIterable {
    case matrix = "Matrix"
    case rain = "Rain"
    case snow = "Snow"
    case ball = "Ball"
    case none = "None"
}

class EasterEggManager: ObservableObject {
    static let shared = EasterEggManager()

    @Published var activeEffect: EasterEggEffect = .none
    @Published var isInverted: Bool = false
    @Published var isEarthquake: Bool = false
    @Published var neonTheme: Bool = false

    private var shakeCount = 0
    private var lastShakeTime = Date.distantPast

    private var konamiSequence: [KonamiKey] = []
    private let targetSequence: [KonamiKey] = [.up, .up, .down, .down, .left, .right, .left, .right, .b, .a]

    enum KonamiKey {
        case up, down, left, right, a, b
    }

    private init() {}

    func handleKonamiKey(_ key: KonamiKey) {
        konamiSequence.append(key)
        if konamiSequence.count > targetSequence.count {
            konamiSequence.removeFirst()
        }

        if konamiSequence == targetSequence {
            triggerKonami()
            konamiSequence.removeAll()
        }
    }

    private func triggerKonami() {
        withAnimation {
            activeEffect = .matrix
        }
        HapticsManager.shared.success()
        ToastManager.shared.show("⬆️⬆️⬇️⬇️⬅️➡️⬅️➡️ B A Unlocked!", type: .success)
    }

    func toggleInversion() {
        withAnimation {
            isInverted.toggle()
        }
        HapticsManager.shared.impact()
        ToastManager.shared.show(isInverted ? "🙃 Colors Inverted!" : "🙂 Colors Restored!", type: .info)
    }

    func triggerRandomEffect() {
        let now = Date()
        if now.timeIntervalSince(lastShakeTime) < 1.0 {
            shakeCount += 1
        } else {
            shakeCount = 1
        }
        lastShakeTime = now

        if shakeCount >= 5 {
            triggerEarthquake()
            shakeCount = 0
            return
        }

        let effects: [EasterEggEffect] = [.matrix, .rain, .snow, .ball]
        withAnimation {
            activeEffect = effects.randomElement() ?? .none
        }
    }

    func stopEffects() {
        withAnimation {
            activeEffect = .none
        }
    }

    func triggerEarthquake() {
        isEarthquake = true
        HapticsManager.shared.error()
        ToastManager.shared.show("🫨 EARTHQUAKE!!!", type: .warning)

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation {
                self.isEarthquake = false
            }
        }
    }
}

struct EasterEggOverlayModifier: ViewModifier {
    @StateObject private var manager = EasterEggManager.shared

    func body(content: Content) -> some View {
        ZStack {
            content
                .grayscale(manager.isInverted ? 1.0 : 0)
                .hueRotation(.degrees(manager.isInverted ? 180 : 0))
                .offset(x: manager.isEarthquake ? CGFloat.random(in: -10...10) : 0,
                        y: manager.isEarthquake ? CGFloat.random(in: -10...10) : 0)
                .shadow(color: manager.neonTheme ? .cyan : .clear, radius: manager.neonTheme ? 10 : 0)
                .shadow(color: manager.neonTheme ? .purple : .clear, radius: manager.neonTheme ? 20 : 0)

            if manager.activeEffect != .none {
                effectView(for: manager.activeEffect)
                    .transition(.opacity)
                    .onTapGesture {
                        manager.stopEffects()
                    }
            }
        }
    }

    @ViewBuilder
    private func effectView(for effect: EasterEggEffect) -> some View {
        switch effect {
        case .matrix:
            MatrixRainView()
        case .rain:
            EmojiRainView(emoji: "🌧️")
        case .snow:
            EmojiRainView(emoji: "❄️")
        case .ball:
            BouncingBallView()
        case .none:
            EmptyView()
        }
    }
}

extension View {
    func withEasterEggs() -> some View {
        self.modifier(EasterEggOverlayModifier())
    }
}

// Placeholder for new effect views
struct EmojiRainView: View {
    let emoji: String
    @State private var items: [EmojiItem] = []
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    struct EmojiItem: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var speed: CGFloat
        var opacity: Double
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(items) { item in
                    Text(emoji)
                        .font(.system(size: 24))
                        .position(x: item.x, y: item.y)
                        .opacity(item.opacity)
                }
            }
            .onReceive(timer) { _ in
                if items.count < 50 {
                    items.append(EmojiItem(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: -50,
                        speed: CGFloat.random(in: 5...15),
                        opacity: Double.random(in: 0.5...1.0)
                    ))
                }

                for i in 0..<items.count {
                    items[i].y += items[i].speed
                }

                items.removeAll { $0.y > geo.size.height + 50 }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct BouncingBallView: View {
    @State private var pos = CGPoint(x: 100, y: 100)
    @State private var vel = CGPoint(x: 5, y: 5)
    let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            Circle()
                .fill(Color.accentColor)
                .frame(width: 50, height: 50)
                .position(pos)
                .onReceive(timer) { _ in
                    var nextPos = CGPoint(x: pos.x + vel.x, y: pos.y + vel.y)

                    if nextPos.x < 25 || nextPos.x > geo.size.width - 25 {
                        vel.x *= -1
                        nextPos.x = pos.x + vel.x
                    }

                    if nextPos.y < 25 || nextPos.y > geo.size.height - 25 {
                        vel.y *= -1
                        nextPos.y = pos.y + vel.y
                    }

                    pos = nextPos
                }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
