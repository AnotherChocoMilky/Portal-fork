import Foundation

struct PairingSession: Codable {
    let sessionID: String
    let createdAt: Date
    let pairingMethod: String // "Nearby" or "Remote"
    let deviceName: String
    let encryptionType: String
    let sessionFingerprint: String
    var isActive: Bool
    let expirationDate: Date?

    // Optional compatibility with legacy fields if needed by other parts of the app
    var udid: String? {
        return sessionID
    }
}
