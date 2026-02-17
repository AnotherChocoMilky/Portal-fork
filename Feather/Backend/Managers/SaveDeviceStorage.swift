import Foundation
import SwiftUI

// MARK: - Save Device Storage Manager
final class SaveDeviceStorage: ObservableObject {
    static let shared = SaveDeviceStorage()

    @AppStorage("Feather.saveDataToDevice") var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                ensureDeviceID()
            }
        }
    }

    private init() {
        if isEnabled {
            ensureDeviceID()
        }
    }

    /// Ensures that a unique device ID exists in the system-level Keychain
    func ensureDeviceID() {
        if !KeychainManager.shared.exists(for: .portalDeviceID) {
            let newID = UUID().uuidString
            do {
                try KeychainManager.shared.save(newID, for: .portalDeviceID)
                AppLogManager.shared.success("Generated and saved new Portal Device ID: \(newID)", category: "Storage")
            } catch {
                AppLogManager.shared.error("Failed to save Portal Device ID to Keychain: \(error.localizedDescription)", category: "Storage")
            }
        }
    }

    /// Retrieves the unique device ID from the Keychain
    func getDeviceID() -> String? {
        do {
            return try KeychainManager.shared.retrieve(for: .portalDeviceID)
        } catch {
            return nil
        }
    }
}
