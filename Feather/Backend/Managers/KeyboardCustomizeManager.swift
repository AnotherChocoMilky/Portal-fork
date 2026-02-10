import SwiftUI
import Combine

class KeyboardCustomizeManager: ObservableObject {
    static let shared = KeyboardCustomizeManager()

    @AppStorage("Feather.keyboard.isEnabled") var isEnabled: Bool = false
    @AppStorage("Feather.keyboard.opacity") var opacity: Double = 0.5
    @AppStorage("Feather.keyboard.blurRadius") var blurRadius: Double = 10.0
    @AppStorage("Feather.keyboard.gradientStart") var gradientStart: String = "#0077BE"
    @AppStorage("Feather.keyboard.gradientEnd") var gradientEnd: String = "#00AEEF"
    @AppStorage("Feather.keyboard.useGradient") var useGradient: Bool = true
    @AppStorage("Feather.keyboard.showAnimatedOrbs") var showAnimatedOrbs: Bool = true

    @Published var keyboardHeight: CGFloat = 0
    @Published var isKeyboardVisible: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var backdropWindow: UIWindow?

    private init() {
        setupObservers()
    }

    private func setupObservers() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                self?.handleKeyboard(notification: notification, visible: true)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                self?.handleKeyboard(notification: notification, visible: false)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                self?.handleKeyboard(notification: notification, visible: true)
            }
            .store(in: &cancellables)

        // Watch for isEnabled changes to hide window immediately if toggled off
        $isEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled in
                if !enabled {
                    self?.hideWindow()
                }
            }
            .store(in: &cancellables)
    }

    private func handleKeyboard(notification: Notification, visible: Bool) {
        guard isEnabled else {
            hideWindow()
            return
        }

        guard let userInfo = notification.userInfo,
              let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }

        let screenSize = UIScreen.main.bounds.size
        // In some cases, keyboardFrame.origin.y is equal to screenSize.height when hidden
        let isActuallyVisible = keyboardFrame.origin.y < screenSize.height
        let height = isActuallyVisible ? (screenSize.height - keyboardFrame.origin.y) : 0

        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25

        withAnimation(.easeOut(duration: duration)) {
            self.keyboardHeight = height
            self.isKeyboardVisible = isActuallyVisible && height > 0
        }

        if self.isKeyboardVisible {
            updateWindow(height: height, duration: duration)
        } else {
            hideWindow(duration: duration)
        }
    }

    private func updateWindow(height: CGFloat, duration: Double) {
        if backdropWindow == nil {
            setupWindow()
        }

        guard let window = backdropWindow else { return }

        let screenSize = UIScreen.main.bounds.size
        // Ensure the window is always at the bottom of the screen
        let frame = CGRect(x: 0, y: screenSize.height - height, width: screenSize.width, height: height)

        window.isHidden = false

        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .curveEaseOut]) {
            window.frame = frame
            window.alpha = 1.0
        }
    }

    private func hideWindow(duration: Double = 0.25) {
        guard let window = backdropWindow else { return }

        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .curveEaseIn], animations: {
            window.alpha = 0
            let screenSize = UIScreen.main.bounds.size
            window.frame.origin.y = screenSize.height
        }) { _ in
            if window.alpha == 0 {
                window.isHidden = true
            }
        }
    }

    private func setupWindow() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .compactMap({ $0 as? UIWindowScene })
            .first ?? (UIApplication.shared.connectedScenes.first as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        // Set window level to be just above the normal window but below the keyboard window (which is much higher)
        window.windowLevel = UIWindow.Level(rawValue: 1)
        window.isUserInteractionEnabled = false
        window.backgroundColor = .clear

        let controller = UIHostingController(rootView: KeyboardBackdropView(manager: self))
        controller.view.backgroundColor = .clear
        window.rootViewController = controller

        self.backdropWindow = window
    }
}

// MARK: - Views and Modifiers

struct KeyboardBackdropView: View {
    @ObservedObject var manager = KeyboardCustomizeManager.shared
    @State private var floatingAnimation = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Base Background
            if manager.useGradient {
                LinearGradient(
                    colors: [Color(hex: manager.gradientStart), Color(hex: manager.gradientEnd)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                Color(uiColor: .systemBackground)
            }

            // Dynamic Animated Orbs
            if manager.showAnimatedOrbs {
                GeometryReader { geo in
                    ZStack {
                        // Primary accent orb
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.accentColor.opacity(0.4),
                                        Color.accentColor.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                            .blur(radius: 40)
                            .offset(x: floatingAnimation ? -30 : 30, y: floatingAnimation ? -20 : 20)
                            .position(x: geo.size.width * 0.2, y: geo.size.height * 0.3)

                        // Secondary orb
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.purple.opacity(0.3),
                                        Color.purple.opacity(0.05),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .blur(radius: 30)
                            .offset(x: floatingAnimation ? 25 : -25, y: floatingAnimation ? 10 : -10)
                            .position(x: geo.size.width * 0.8, y: geo.size.height * 0.7)

                        // Tertiary orb
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.cyan.opacity(0.2),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                            .offset(x: floatingAnimation ? -15 : 15, y: floatingAnimation ? 20 : -20)
                            .position(x: geo.size.width * 0.5, y: geo.size.height * 0.8)
                    }
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                        floatingAnimation = true
                    }
                }
            }
        }
        .blur(radius: manager.blurRadius)
        .opacity(manager.opacity)
        .allowsHitTesting(false)
    }
}

struct KeyboardBackdropModifier: ViewModifier {
    @ObservedObject var manager = KeyboardCustomizeManager.shared

    func body(content: Content) -> some View {
        // The backdrop is now managed globally via a UIWindow in KeyboardCustomizeManager.
        // This modifier remains for compatibility but no longer adds its own backdrop view.
        content
    }
}

extension View {
    func withKeyboardBackdrop() -> some View {
        self.modifier(KeyboardBackdropModifier())
    }
}
