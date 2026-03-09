import Foundation
import Security

enum PasswordChangerError: LocalizedError {
    case importFailed(OSStatus)
    case exportFailed(OSStatus)
    case noItemsFound
    case invalidData
    case notSupported
    case authFailed
    case decodeFailed
    case invalidParam

    var errorDescription: String? {
        switch self {
        case .importFailed(let status):
            return "Failed to import P12 (OSStatus \(status))"
        case .exportFailed(let status):
            return "Failed to export P12 (OSStatus \(status))"
        case .noItemsFound:
            return "No identities found in the P12 file"
        case .invalidData:
            return "Invalid P12 data"
        case .notSupported:
            return "This operation is not supported on this platform"
        case .authFailed:
            return "Incorrect password for the certificate"
        case .decodeFailed:
            return "The certificate file is corrupted or not a valid PKCS#12 file"
        case .invalidParam:
            return "Invalid PKCS#12 file or parameters"
        }
    }
}

class PasswordChanger {
    /// Changes the password of a PKCS#12 (.p12) file.
    /// This operation is performed entirely in memory.
    static func changePassword(p12Data: Data, oldPassword: String, newPassword: String) throws -> Data {
        // Trim whitespace and newline characters from passwords; never pass nil
        let trimmedOldPassword = oldPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNewPassword = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        // Always provide a valid password string (empty string is valid for passwordless P12 files)
        let importOptions: NSDictionary = [
            kSecImportExportPassphrase: trimmedOldPassword
        ]

        var rawItems: CFArray?
        let importStatus = SecPKCS12Import(p12Data as CFData, importOptions, &rawItems)

        // Map common import errors to clear messages
        guard importStatus == errSecSuccess else {
            switch importStatus {
            case errSecAuthFailed:
                throw PasswordChangerError.authFailed
            case errSecDecode:
                throw PasswordChangerError.decodeFailed
            case errSecParam:
                throw PasswordChangerError.invalidParam
            default:
                throw PasswordChangerError.importFailed(importStatus)
            }
        }

        // Safely unwrap the returned array
        guard let items = rawItems as? [[String: Any]], !items.isEmpty else {
            throw PasswordChangerError.noItemsFound
        }

        // Extract SecIdentity using kSecImportItemIdentity
        var exportItems: [Any] = []
        for item in items {
            if let identity = item[kSecImportItemIdentity as String] {
                exportItems.append(identity)
            }
            if let certChain = item[kSecImportItemCertChain as String] as? [Any] {
                exportItems.append(contentsOf: certChain)
            }
        }

        if exportItems.isEmpty {
            throw PasswordChangerError.noItemsFound
        }

        #if os(macOS)
        var keyParams = SecItemImportExportKeyParameters()
        keyParams.version = UInt32(kSecKeyImportExportParamsVersion)

        // Provide the new password through kSecExportPassphrase
        let passwordCF = trimmedNewPassword as CFString
        keyParams.passphrase = Unmanaged.passRetained(passwordCF)

        var exportedData: CFData?
        let exportStatus = SecItemExport(
            exportItems as CFArray,
            SecExternalFormat.formatPKCS12,
            [],
            &keyParams,
            &exportedData
        )

        // Release the retained CFString
        keyParams.passphrase?.release()

        guard exportStatus == errSecSuccess, let resultData = exportedData as Data? else {
            throw PasswordChangerError.exportFailed(exportStatus)
        }

        return resultData
        #else
        // On non-macOS platforms, SecItemExport for PKCS12 is not available in the public Security framework.
        throw PasswordChangerError.notSupported
        #endif
    }
}
