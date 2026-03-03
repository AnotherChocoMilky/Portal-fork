//
//  PairingManager.swift
//  Feather
//

import Foundation
import IDevice
import OSLog

// MARK: - PairingManager

/// Responsible for managing the pairing file lifecycle: import, validation, and storage.
/// The pairing file is stored at `Documents/pairingFile.plist`.
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

    /// Imports a pairing file from the given URL and validates it.
    /// - Parameter sourceURL: The URL of the .plist or .mobiledevicepairing file selected by the user.
    func importPairingFile(from sourceURL: URL) throws {
        let fileManager = FileManager.default
        let destURL = URL(fileURLWithPath: Self.pairingFilePath)

        try? fileManager.removeItem(at: destURL)
        try fileManager.copyItem(at: sourceURL, to: destURL)

        guard validatePairingFile() else {
            try? fileManager.removeItem(at: destURL)
            throw JITError.pairingInvalid
        }

        Logger.jit.info("PairingManager: Successfully imported and validated pairing file")
    }

    /// Validates the pairing file currently on disk by asking idevice to parse it.
    /// - Returns: `true` if idevice can successfully read the pairing file.
    func validatePairingFile() -> Bool {
        guard hasPairingFile else { return false }
        var pairingFile: OpaquePointer?
        let err = idevice_pairing_file_read(Self.pairingFilePath, &pairingFile)
        if let err = err {
            Logger.jit.error("PairingManager: Validation failed with error code \(err.pointee.code)")
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
    /// - Throws: `JITError.pairingMissing` or `JITError.pairingInvalid`.
    func readPairingFile() throws -> OpaquePointer {
        guard hasPairingFile else {
            throw JITError.pairingMissing
        }
        var pairingFile: OpaquePointer?
        let err = idevice_pairing_file_read(Self.pairingFilePath, &pairingFile)
        if let err = err {
            idevice_error_free(err)
            throw JITError.pairingInvalid
        }
        guard let pf = pairingFile else {
            throw JITError.pairingInvalid
        }
        return pf
    }

    // MARK: - Remove

    func removePairingFile() {
        try? FileManager.default.removeItem(atPath: Self.pairingFilePath)
        Logger.jit.info("PairingManager: Removed pairing file")
    }
}
