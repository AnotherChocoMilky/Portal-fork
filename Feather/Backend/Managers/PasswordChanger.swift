import Foundation
import Security
#if !os(macOS)
import ZsignSwift
#endif

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
            return "Incorrect password or unsupported encryption"
        case .decodeFailed:
            return "The file may be malformed or is not a valid PKCS#12 file"
        case .invalidParam:
            return "A parameter error occurred; the PKCS#12 format may not be supported"
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

        #if os(macOS)
        // On macOS use the Security framework: SecPKCS12Import for validation then SecItemExport to re-encrypt.
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

        // Extract SecIdentity using kSecImportItemIdentity and confirm both certificate and private key exist
        guard let identity = items[0][kSecImportItemIdentity as String] as? SecIdentity else {
            throw PasswordChangerError.noItemsFound
        }

        var certificate: SecCertificate?
        guard SecIdentityCopyCertificate(identity, &certificate) == errSecSuccess, certificate != nil else {
            throw PasswordChangerError.noItemsFound
        }

        var privateKey: SecKey?
        guard SecIdentityCopyPrivateKey(identity, &privateKey) == errSecSuccess, privateKey != nil else {
            throw PasswordChangerError.noItemsFound
        }

        // Build the export items array with identity and any intermediate certificates
        var exportItems: [Any] = [identity]
        if let certChain = items[0][kSecImportItemCertChain as String] as? [Any] {
            exportItems.append(contentsOf: certChain)
        }

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
        // On iOS, use the bundled OpenSSL (via Zsign) to change the PKCS#12 password entirely in memory.
        // This avoids SecItemExport (unavailable on iOS for PKCS#12) and never touches the system keychain.
        var outputData: NSData?
        let status = Zsign.changeP12Password(p12Data: p12Data as NSData, oldPassword: trimmedOldPassword as NSString, newPassword: trimmedNewPassword as NSString, outputData: &outputData)

        switch status {
        case Zsign.p12ChangeSuccess:
            guard let resultData = outputData as Data? else {
                throw PasswordChangerError.exportFailed(0)
            }
            return resultData
        case Zsign.p12ChangeDecodeError:
            throw PasswordChangerError.decodeFailed
        case Zsign.p12ChangeAuthError:
            throw PasswordChangerError.authFailed
        default:
            throw PasswordChangerError.exportFailed(OSStatus(status))
        }
        #endif
    }
}
