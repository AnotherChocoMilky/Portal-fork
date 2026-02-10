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
    }

    private func handleKeyboard(notification: Notification, visible: Bool) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25

        withAnimation(.easeOut(duration: duration)) {
            self.keyboardHeight = visible ? keyboardFrame.height : 0
            self.isKeyboardVisible = visible
        }
    }
}
