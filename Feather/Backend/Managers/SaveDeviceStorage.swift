import Foundation
import SwiftUI

// MARK: - Save Device Storage Manager
final class SaveDeviceStorage: ObservableObject {
    static let shared = SaveDeviceStorage()

    @AppStorage("Feather.saveDataToDevice") var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                ensureDeviceID()
                migrateData(toAppGroup: true)
            } else {
                migrateData(toAppGroup: false)
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
            // Use hardware ID if possible, otherwise persistent UUID
            let newID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            do {
                try KeychainManager.shared.save(newID, for: .portalDeviceID)
                AppLogManager.shared.success("Generated and saved new Portal Device ID: \(newID)", category: "Storage")
            } catch {
                AppLogManager.shared.error("Failed to save Portal Device ID to Keychain: \(error.localizedDescription)", category: "Storage")
            }
        }
    }

    /// Migrates data between local container and App Group
    private func migrateData(toAppGroup: Bool) {
        let fileManager = FileManager.default
        let localDocuments = URL.documentsDirectory
        let appGroupID = Storage.appGroupID

        guard let groupContainer = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            AppLogManager.shared.error("App Group container not found during migration", category: "Storage")
            return
        }

        let groupDocuments = groupContainer.appendingPathComponent("Documents", isDirectory: true)

        let sourceDocs = toAppGroup ? localDocuments : groupDocuments
        let targetDocs = toAppGroup ? groupDocuments : localDocuments

        // Ensure target parent exists
        try? fileManager.createDirectory(at: targetDocs, withIntermediateDirectories: true)

        // Migrate Documents
        do {
            let items = try fileManager.contentsOfDirectory(at: sourceDocs, includingPropertiesForKeys: nil)
            for item in items {
                let targetItem = targetDocs.appendingPathComponent(item.lastPathComponent)
                if !fileManager.fileExists(atPath: targetItem.path) {
                    try fileManager.moveItem(at: item, to: targetItem)
                }
            }
            AppLogManager.shared.success("Migrated documents to \(toAppGroup ? "App Group" : "Local")", category: "Storage")
        } catch {
            AppLogManager.shared.error("Failed to migrate documents: \(error.localizedDescription)", category: "Storage")
        }

        // Migrate Core Data
        let dbName = "Feather"
        let localSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let sourceDBDir = toAppGroup ? localSupport : groupContainer
        let targetDBDir = toAppGroup ? groupContainer : localSupport

        let extensions = ["sqlite", "sqlite-shm", "sqlite-wal"]
        for ext in extensions {
            let sourceFile = sourceDBDir.appendingPathComponent("\(dbName).\(ext)")
            let targetFile = targetDBDir.appendingPathComponent("\(dbName).\(ext)")

            if fileManager.fileExists(atPath: sourceFile.path) {
                do {
                    if fileManager.fileExists(atPath: targetFile.path) {
                        try fileManager.removeItem(at: targetFile)
                    }
                    try fileManager.moveItem(at: sourceFile, to: targetFile)
                    AppLogManager.shared.success("Migrated \(dbName).\(ext) to \(toAppGroup ? "App Group" : "Local")", category: "Storage")
                } catch {
                    AppLogManager.shared.error("Failed to migrate \(dbName).\(ext): \(error.localizedDescription)", category: "Storage")
                }
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
