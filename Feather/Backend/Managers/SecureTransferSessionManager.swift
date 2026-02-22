import Foundation

class SecureTransferSessionManager {
    static let shared = SecureTransferSessionManager()

    private let sessionFileName = "secureTransferSession.plist"

    private var sessionFileURL: URL {
        return URL.documentsDirectory.appendingPathComponent(sessionFileName)
    }

    private init() {}

    func sessionExists() -> Bool {
        return FileManager.default.fileExists(atPath: sessionFileURL.path)
    }

    func saveSession(_ session: SecureTransferSession) {
        do {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            let data = try encoder.encode(session)
            try data.write(to: sessionFileURL, options: .atomic)
            AppLogManager.shared.success("Secure transfer session saved: \(session.remoteDeviceName)", category: "Session")
        } catch {
            AppLogManager.shared.error("Failed to save secure transfer session: \(error.localizedDescription)", category: "Session")
        }
    }

    func loadSession() -> SecureTransferSession? {
        guard sessionExists() else {
            return nil
        }

        do {
            let data = try Data(contentsOf: sessionFileURL)
            let decoder = PropertyListDecoder()
            return try decoder.decode(SecureTransferSession.self, from: data)
        } catch {
            AppLogManager.shared.error("Failed to load secure transfer session: \(error.localizedDescription)", category: "Session")
            return nil
        }
    }

    func deactivateSession() {
        if var session = loadSession() {
            session.isActive = false
            saveSession(session)
            AppLogManager.shared.info("Secure transfer session deactivated", category: "Session")
        }
    }

    func deleteSession() {
        do {
            if sessionExists() {
                try FileManager.default.removeItem(at: sessionFileURL)
                AppLogManager.shared.info("Secure transfer session deleted", category: "Session")
            }
        } catch {
            AppLogManager.shared.error("Failed to delete secure transfer session: \(error.localizedDescription)", category: "Session")
        }
    }

    func isSessionActive() -> Bool {
        guard let session = loadSession() else { return false }
        return isSessionValid(session)
    }

    func isSessionValid(_ session: SecureTransferSession) -> Bool {
        guard session.isActive else { return false }
        return !validateExpiration(session)
    }

    func validateExpiration(_ session: SecureTransferSession) -> Bool {
        if let expirationDate = session.expirationDate {
            return expirationDate < Date()
        }
        return false
    }

    func recordSessionAuthenticated(method: String, remoteDeviceName: String, encryptionType: String = "AES-256") {
        let session = SecureTransferSession(
            sessionID: UUID(),
            createdAt: Date(),
            transferMethod: method,
            remoteDeviceName: remoteDeviceName,
            encryptionType: encryptionType,
            sessionFingerprint: String(UUID().uuidString.prefix(8)).uppercased(),
            isActive: true,
            expirationDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
        )
        saveSession(session)
    }
}
