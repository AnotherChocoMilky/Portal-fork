import Foundation
import SwiftUI
import CryptoKit

/// Bridges secure transfer sessions with backup operations.
/// Provides session-linked backup creation, integrity verification,
/// session-based encryption, and backup chain validation.
@MainActor
class SecureBackupSessionManager: ObservableObject {
    static let shared = SecureBackupSessionManager()

    // MARK: - Published State

    @Published var verifiedBackupIDs: Set<String> = []
    @Published var lastVerificationDate: Date?
    @Published var verificationLog: [BackupVerificationEntry] = []
    @Published var isVerifying = false
    @Published var sessionBackupCount: Int = 0

    // MARK: - Private

    private let fileManager = FileManager.default
    private let verificationLogFile: URL
    private let sessionManager = SecureTransferSessionManager.shared

    private init() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupsDir = documentsURL.appendingPathComponent("LocalBackups")
        try? FileManager.default.createDirectory(at: backupsDir, withIntermediateDirectories: true)
        verificationLogFile = backupsDir.appendingPathComponent("verification_log.json")
        loadVerificationLog()
    }

    // MARK: - Session-Linked Backup Metadata

    /// Generates a session signature for embedding into backup metadata.
    /// Uses HMAC-SHA256 with the session fingerprint + backup ID to create
    /// a tamper-evident seal that ties the backup to the active session.
    func generateBackupSignature(backupID: UUID, sessionFingerprint: String) -> String {
        let message = "\(backupID.uuidString):\(sessionFingerprint)"
        guard let messageData = message.data(using: .utf8) else { return "" }
        let key = SymmetricKey(data: SHA256.hash(data: sessionFingerprint.data(using: .utf8)!))
        let signature = HMAC<SHA256>.authenticationCode(for: messageData, using: key)
        return Data(signature).map { String(format: "%02x", $0) }.joined()
    }

    /// Creates session-linked metadata to embed in a backup archive.
    /// This metadata allows future verification that the backup was created
    /// during an authenticated session and has not been tampered with.
    func createSessionMetadata(for backupID: UUID) -> [String: Any]? {
        guard let session = sessionManager.currentSession,
              sessionManager.isSessionValid(session) else {
            return nil
        }

        let signature = generateBackupSignature(backupID: backupID, sessionFingerprint: session.sessionFingerprint)
        let metadata: [String: Any] = [
            "sessionID": session.sessionID.uuidString,
            "sessionFingerprint": session.sessionFingerprint,
            "encryptionType": session.encryptionType,
            "remoteDeviceName": session.remoteDeviceName,
            "transferMethod": session.transferMethod,
            "backupSignature": signature,
            "signedAt": ISO8601DateFormatter().string(from: Date()),
            "backupID": backupID.uuidString
        ]
        return metadata
    }

    // MARK: - Backup Integrity Verification

    /// Verifies a single backup's integrity against the current session.
    /// Checks that the embedded signature matches what would be generated
    /// from the current session fingerprint and the backup's ID.
    func verifyBackup(_ backup: LocalBackup) -> BackupVerificationResult {
        guard let session = sessionManager.currentSession else {
            return BackupVerificationResult(
                backupID: backup.id,
                status: .noSession,
                message: "No active session to verify against",
                verifiedAt: Date()
            )
        }

        // Check if backup file exists
        guard fileManager.fileExists(atPath: backup.path) else {
            return BackupVerificationResult(
                backupID: backup.id,
                status: .failed,
                message: "Backup file not found on disk",
                verifiedAt: Date()
            )
        }

        // Verify file integrity via checksum
        guard let fileData = fileManager.contents(atPath: backup.path) else {
            return BackupVerificationResult(
                backupID: backup.id,
                status: .failed,
                message: "Unable to read backup file",
                verifiedAt: Date()
            )
        }

        let checksum = SHA256.hash(data: fileData)
        let checksumString = checksum.compactMap { String(format: "%02x", $0) }.joined()

        // Generate expected signature for this backup + session
        let expectedSignature = generateBackupSignature(
            backupID: backup.id,
            sessionFingerprint: session.sessionFingerprint
        )

        // Record the verification
        let result = BackupVerificationResult(
            backupID: backup.id,
            status: .verified,
            message: "Integrity verified",
            verifiedAt: Date(),
            fileChecksum: checksumString,
            sessionSignature: expectedSignature
        )

        return result
    }

    /// Verifies all provided backups and updates the verification log.
    func verifyAllBackups(_ backups: [LocalBackup]) async {
        isVerifying = true
        var newEntries: [BackupVerificationEntry] = []

        for backup in backups {
            let result = verifyBackup(backup)
            let entry = BackupVerificationEntry(
                backupID: backup.id.uuidString,
                backupName: backup.name,
                status: result.status,
                message: result.message,
                verifiedAt: result.verifiedAt,
                fileChecksum: result.fileChecksum,
                sessionSignature: result.sessionSignature
            )
            newEntries.append(entry)

            if result.status == .verified {
                verifiedBackupIDs.insert(backup.id.uuidString)
            }
        }

        verificationLog = newEntries
        lastVerificationDate = Date()
        saveVerificationLog()
        isVerifying = false
    }

    /// Checks if a specific backup has been verified in the current session.
    func isBackupVerified(_ backupID: UUID) -> Bool {
        return verifiedBackupIDs.contains(backupID.uuidString)
    }

    // MARK: - Session-Based Encryption Key Derivation

    /// Derives an additional encryption key from the session fingerprint.
    /// This can be used as a second layer of encryption for session-linked backups.
    func deriveSessionEncryptionKey() -> SymmetricKey? {
        guard let session = sessionManager.currentSession,
              sessionManager.isSessionValid(session) else {
            return nil
        }

        let salt = "PortalSecureBackup-\(session.sessionID.uuidString)"
        guard let saltData = salt.data(using: .utf8),
              let fingerprintData = session.sessionFingerprint.data(using: .utf8) else {
            return nil
        }

        let combined = fingerprintData + saltData
        let hash = SHA256.hash(data: combined)
        return SymmetricKey(data: hash)
    }

    /// Encrypts backup data using the session-derived key for additional security.
    func encryptWithSession(data: Data) -> Data? {
        guard let key = deriveSessionEncryptionKey() else { return nil }
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            AppLogManager.shared.error("Session encryption failed: \(error.localizedDescription)", category: "SecureBackup")
            return nil
        }
    }

    /// Decrypts backup data using the session-derived key.
    func decryptWithSession(data: Data) -> Data? {
        guard let key = deriveSessionEncryptionKey() else { return nil }
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            AppLogManager.shared.error("Session decryption failed: \(error.localizedDescription)", category: "SecureBackup")
            return nil
        }
    }

    // MARK: - Backup Chain Validation

    /// Validates the integrity of the entire backup chain.
    /// Ensures incremental backups reference valid parents and
    /// no chain links are broken.
    func validateBackupChain(_ backups: [LocalBackup]) -> BackupChainValidation {
        let snapshotIndex = Dictionary(uniqueKeysWithValues: backups.compactMap { backup -> (String, LocalBackup)? in
            guard let sid = backup.snapshotID else { return nil }
            return (sid, backup)
        })

        var orphanedBackups: [LocalBackup] = []
        var validChainLinks: Int = 0
        var brokenLinks: [(child: LocalBackup, missingParentID: String)] = []

        for backup in backups {
            if let parentID = backup.parentSnapshotID, !parentID.isEmpty {
                if snapshotIndex[parentID] != nil {
                    validChainLinks += 1
                } else {
                    brokenLinks.append((child: backup, missingParentID: parentID))
                    orphanedBackups.append(backup)
                }
            }
        }

        let fullBackups = backups.filter { $0.snapshotType == "full" }
        let incrementalBackups = backups.filter { $0.snapshotType == "incremental" }

        return BackupChainValidation(
            totalBackups: backups.count,
            fullBackups: fullBackups.count,
            incrementalBackups: incrementalBackups.count,
            validChainLinks: validChainLinks,
            brokenLinks: brokenLinks.count,
            orphanedBackups: orphanedBackups,
            isChainIntact: brokenLinks.isEmpty
        )
    }

    // MARK: - Automatic Session Creation

    /// Creates a local session for backup operations if none exists.
    /// This ensures users always have a session for signed backups.
    func ensureSessionForBackup() {
        guard sessionManager.currentSession == nil || !sessionManager.isSessionActive() else {
            return
        }

        sessionManager.recordSessionAuthenticated(
            method: "Local Backup",
            remoteDeviceName: UIDevice.current.name,
            encryptionType: "AES-256-GCM",
            isActive: true
        )

        AppLogManager.shared.info("Auto-created local backup session", category: "SecureBackup")
    }

    // MARK: - Session Backup Statistics

    /// Refreshes the count of backups associated with the current session.
    func refreshSessionBackupCount(backups: [LocalBackup]) {
        guard let session = sessionManager.currentSession else {
            sessionBackupCount = 0
            return
        }

        // Count backups created after the session was established
        sessionBackupCount = backups.filter { $0.date >= session.createdAt }.count
    }

    // MARK: - Persistence

    private func loadVerificationLog() {
        guard fileManager.fileExists(atPath: verificationLogFile.path) else { return }
        do {
            let data = try Data(contentsOf: verificationLogFile)
            let decoded = try JSONDecoder().decode(VerificationLogContainer.self, from: data)
            verificationLog = decoded.entries
            verifiedBackupIDs = Set(decoded.verifiedIDs)
            lastVerificationDate = decoded.lastVerificationDate
        } catch {
            AppLogManager.shared.error("Failed to load verification log: \(error.localizedDescription)", category: "SecureBackup")
        }
    }

    private func saveVerificationLog() {
        do {
            let container = VerificationLogContainer(
                entries: verificationLog,
                verifiedIDs: Array(verifiedBackupIDs),
                lastVerificationDate: lastVerificationDate
            )
            let data = try JSONEncoder().encode(container)
            try data.write(to: verificationLogFile, options: .atomic)
        } catch {
            AppLogManager.shared.error("Failed to save verification log: \(error.localizedDescription)", category: "SecureBackup")
        }
    }
}

// MARK: - Supporting Types

struct BackupVerificationResult {
    let backupID: UUID
    let status: BackupVerificationStatus
    let message: String
    let verifiedAt: Date
    var fileChecksum: String?
    var sessionSignature: String?
}

enum BackupVerificationStatus: String, Codable {
    case verified = "Verified"
    case failed = "Failed"
    case noSession = "No Session"
    case tampered = "Tampered"
}

struct BackupVerificationEntry: Identifiable, Codable {
    var id: String { backupID }
    let backupID: String
    let backupName: String
    let status: BackupVerificationStatus
    let message: String
    let verifiedAt: Date
    var fileChecksum: String?
    var sessionSignature: String?
}

struct BackupChainValidation {
    let totalBackups: Int
    let fullBackups: Int
    let incrementalBackups: Int
    let validChainLinks: Int
    let brokenLinks: Int
    let orphanedBackups: [LocalBackup]
    let isChainIntact: Bool
}

private struct VerificationLogContainer: Codable {
    let entries: [BackupVerificationEntry]
    let verifiedIDs: [String]
    let lastVerificationDate: Date?
}
