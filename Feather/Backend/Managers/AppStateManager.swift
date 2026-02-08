import Foundation

class AppStateManager: ObservableObject {
    static let shared = AppStateManager()
    @Published var hasSelectedInitialTab = false

    private init() {}
}
