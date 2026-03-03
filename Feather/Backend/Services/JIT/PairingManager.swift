//
//  PairingManager.swift
//  Feather
//

import Foundation
import IDevice

// MARK: - PairingManager

/// Responsible for managing the pairing file lifecycle: import, validation, and storage.
/// The pairing file is stored at `Documents/pairingFile.plist`, consistent with HeartbeatManager.
class PairingManager {
    static let shared = PairingManager()

    private init() {}

    // MARK: - Status

    /// Whether a pairing file is currently stored on disk.
    var hasPairingFile: Bool {
        FileManager.default.fileExists(atPath: Self.pairingFilePath)
    }

    // MARK: - Paths

    static var pairingFilePath: String {
        URL.documentsDirectory.appendingPathComponent("pairingFile.plist").path()
    }

    // MARK: - Import

    /// Imports a pairing file from the given URL, validates it, and writes it to the canonical path.
    /// The actual file move is delegated to `FR.movePairing(_:)` which handles security-scoped
    /// resource access and file system operations. This method validates the result.
    /// - Parameter sourceURL: The URL of the .plist or .mobiledevicepairing file selected by the user.
    func importPairingFile(from sourceURL: URL) {
        FR.movePairing(sourceURL)
    }

    /// Validates the pairing file currently on disk by asking idevice to parse it.
    /// - Returns: `true` if idevice can successfully read the pairing file.
    func validatePairingFile() -> Bool {
        guard hasPairingFile else { return false }
        var pairingFile: OpaquePointer?
        let err = idevice_pairing_file_read(Self.pairingFilePath, &pairingFile)
        if let err = err {
            idevice_error_free(err)
            return false
        }
        if let pf = pairingFile {
            idevice_pairing_file_free(pf)
        }
        return true
    }

    /// Returns an opaque pointer to a freshly-read pairing file.
    /// The caller is responsible for freeing the pointer via `idevice_pairing_file_free`.
    /// - Throws: `JITError.pairingFileNotFound` or `JITError.pairingFileInvalid`.
    func readPairingFile() throws -> OpaquePointer {
        guard hasPairingFile else {
            throw JITError.pairingFileNotFound
        }
        var pairingFile: OpaquePointer?
        let err = idevice_pairing_file_read(Self.pairingFilePath, &pairingFile)
        if let err = err {
            let code = err.pointee.code
            idevice_error_free(err)
            throw JITError.pairingFileInvalid("idevice error code \(code)")
        }
        guard let pf = pairingFile else {
            throw JITError.pairingFileInvalid("Nil pointer returned")
        }
        return pf
    }

    // MARK: - Remove

    func removePairingFile() {
        try? FileManager.default.removeItem(atPath: Self.pairingFilePath)
    }
}
