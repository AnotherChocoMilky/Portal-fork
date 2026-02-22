import Foundation

class PairingSessionManager {
    static let shared = PairingSessionManager()

    private let pairingFileName = "pairingFile.plist"

    private var pairingFileURL: URL {
        return URL.documentsDirectory.appendingPathComponent(pairingFileName)
    }

    private init() {}

    func sessionExists() -> Bool {
        return FileManager.default.fileExists(atPath: pairingFileURL.path)
    }

    func saveSession(_ session: PairingSession) {
        do {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            let data = try encoder.encode(session)
            try data.write(to: pairingFileURL, options: .atomic)
            AppLogManager.shared.success("Pairing session saved: \(session.deviceName)", category: "Pairing")
        } catch {
            AppLogManager.shared.error("Failed to save pairing session: \(error.localizedDescription)", category: "Pairing")
        }
    }

    func loadSession() -> PairingSession? {
        guard sessionExists() else {
            return nil
        }

        do {
            let data = try Data(contentsOf: pairingFileURL)
            let decoder = PropertyListDecoder()
            return try decoder.decode(PairingSession.self, from: data)
        } catch {
            AppLogManager.shared.error("Failed to load pairing session: \(error.localizedDescription)", category: "Pairing")
            return nil
        }
    }

    func deactivateSession() {
        if var session = loadSession() {
            session.isActive = false
            saveSession(session)
            AppLogManager.shared.info("Pairing session deactivated", category: "Pairing")
        }
    }

    func deleteSession() {
        do {
            if sessionExists() {
                try FileManager.default.removeItem(at: pairingFileURL)
                AppLogManager.shared.info("Pairing session deleted", category: "Pairing")
            }
        } catch {
            AppLogManager.shared.error("Failed to delete pairing session: \(error.localizedDescription)", category: "Pairing")
        }
    }

    func isSessionValid(_ session: PairingSession) -> Bool {
        guard session.isActive else { return false }

        if let expirationDate = session.expirationDate {
            return expirationDate > Date()
        }

        return true
    }
}
