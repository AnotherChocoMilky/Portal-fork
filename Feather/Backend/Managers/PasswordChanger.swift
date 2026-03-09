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
    case unsupportedEncryption
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
            return "The password for this certificate is incorrect."
        case .decodeFailed:
            return "The certificate file is corrupted or not a valid PKCS#12 file."
        case .unsupportedEncryption:
            return "This certificate uses an unsupported encryption method. Re-export the certificate from Keychain Access as a standard PKCS#12 file."
        case .invalidParam:
            return "A parameter error occurred; the PKCS#12 format may not be supported"
        }
    }
}

/// Structured result from a successful PKCS#12 validation.
struct P12ValidationResult {
    /// Human-readable signing identity (e.g. "iPhone Distribution: Company (TEAM_ID)").
    let signingIdentity: String
    /// Apple Team ID extracted from the certificate subject, if available.
    let teamID: String?
    /// Certificate expiration date, if it could be determined.
    let expirationDate: Date?
    /// Whether the certificate passed trust evaluation.
    let isVerified: Bool
}

class PasswordChanger {

    // MARK: - PKCS#12 Validation

    /// Validates a PKCS#12 blob using the Apple Security framework and returns
    /// structured certificate information.
    ///
    /// Uses `SecPKCS12Import` with `kSecImportExportPassphrase` to parse the data
    /// and captures the identity, certificate chain, and private key. Distinguishes
    /// between incorrect password, unsupported encryption, and invalid file errors.
    static func validateP12(p12Data: Data, password: String) throws -> P12ValidationResult {
        guard !p12Data.isEmpty else {
            throw PasswordChangerError.invalidData
        }

        // Quick structural check: a DER-encoded PKCS#12 (PFX) starts with a SEQUENCE tag (0x30).
        guard p12Data.first == 0x30 else {
            throw PasswordChangerError.decodeFailed
        }

        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        let importOptions: NSDictionary = [
            kSecImportExportPassphrase: trimmedPassword
        ]

        var rawItems: CFArray?
        let importStatus = SecPKCS12Import(p12Data as CFData, importOptions, &rawItems)

        guard importStatus == errSecSuccess else {
            switch importStatus {
            case errSecAuthFailed:
                throw PasswordChangerError.authFailed
            case errSecDecode:
                // Data looks like DER (passed the 0x30 check) but the Security
                // framework cannot decode it — most likely an unsupported encryption
                // algorithm (e.g. PBES2/AES exported by newer macOS).
                throw PasswordChangerError.unsupportedEncryption
            case errSecParam:
                throw PasswordChangerError.unsupportedEncryption
            default:
                throw PasswordChangerError.importFailed(importStatus)
            }
        }

        guard let items = rawItems as? [[String: Any]], !items.isEmpty else {
            throw PasswordChangerError.noItemsFound
        }

        // Extract the signing identity
        let identityValue = items[0][kSecImportItemIdentity as String] as AnyObject
        guard CFGetTypeID(identityValue) == SecIdentityGetTypeID() else {
            throw PasswordChangerError.noItemsFound
        }
        let identity = identityValue as! SecIdentity

        var certificate: SecCertificate?
        guard SecIdentityCopyCertificate(identity, &certificate) == errSecSuccess,
              let cert = certificate else {
            throw PasswordChangerError.noItemsFound
        }

        // Confirm the private key exists
        var privateKey: SecKey?
        guard SecIdentityCopyPrivateKey(identity, &privateKey) == errSecSuccess,
              privateKey != nil else {
            throw PasswordChangerError.noItemsFound
        }

        // Signing identity name
        let signingIdentity = (SecCertificateCopySubjectSummary(cert) as String?) ?? "Unknown Identity"

        // Team ID (extracted from the subject summary when it matches "… (XXXXXXXXXX)")
        let teamID = _extractTeamID(from: signingIdentity)

        // Expiration date
        let expirationDate = _extractExpirationDate(from: cert)

        // Trust evaluation
        let isVerified = _evaluateTrust(certificate: cert, items: items)

        return P12ValidationResult(
            signingIdentity: signingIdentity,
            teamID: teamID,
            expirationDate: expirationDate,
            isVerified: isVerified
        )
    }

    // MARK: - Password Change

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
            throw _mapImportError(importStatus, p12Data: p12Data)
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
        let status = Zsign.changeP12Password(p12Data: p12Data, oldPassword: trimmedOldPassword, newPassword: trimmedNewPassword, outputData: &outputData)

        switch status {
        case Zsign.p12ChangeSuccess:
            guard let resultData = outputData as Data? else {
                throw PasswordChangerError.exportFailed(0)
            }
            return resultData
        case Zsign.p12ChangeDecodeError:
            // Distinguish between invalid file and unsupported encryption
            if p12Data.first == 0x30 {
                throw PasswordChangerError.unsupportedEncryption
            }
            throw PasswordChangerError.decodeFailed
        case Zsign.p12ChangeAuthError:
            throw PasswordChangerError.authFailed
        default:
            throw PasswordChangerError.exportFailed(OSStatus(status))
        }
        #endif
    }

    // MARK: - Private Helpers

    /// Maps a `SecPKCS12Import` error to the appropriate `PasswordChangerError`,
    /// using a basic DER check to distinguish unsupported encryption from a
    /// corrupted / non-PKCS#12 file.
    private static func _mapImportError(_ status: OSStatus, p12Data: Data) -> PasswordChangerError {
        switch status {
        case errSecAuthFailed:
            return .authFailed
        case errSecDecode:
            return p12Data.first == 0x30 ? .unsupportedEncryption : .decodeFailed
        case errSecParam:
            return p12Data.first == 0x30 ? .unsupportedEncryption : .invalidParam
        default:
            return .importFailed(status)
        }
    }

    private static let _teamIDRegex = try? NSRegularExpression(pattern: #"\(([A-Z0-9]{10})\)\s*$"#)

    /// Attempts to extract a 10-character Apple Team ID from a signing identity
    /// string such as "iPhone Distribution: Company Name (ABCDE12345)".
    private static func _extractTeamID(from summary: String) -> String? {
        guard let regex = _teamIDRegex else { return nil }
        let range = NSRange(summary.startIndex..., in: summary)
        guard let match = regex.firstMatch(in: summary, range: range),
              match.numberOfRanges > 1,
              let teamRange = Range(match.range(at: 1), in: summary) else {
            return nil
        }
        return String(summary[teamRange])
    }

    /// Extracts the certificate expiration date (notAfter) by walking the DER-
    /// encoded X.509 structure returned by `SecCertificateCopyData`.
    private static func _extractExpirationDate(from certificate: SecCertificate) -> Date? {
        let derData = SecCertificateCopyData(certificate) as Data
        guard derData.count > 4 else { return nil }

        // Walk ASN.1: Certificate → TBSCertificate → skip version, serial,
        // signatureAlgorithm, issuer → Validity → notBefore, notAfter.
        var offset = 0

        // Helper: read tag + length, return (contentOffset, contentLength)
        func readTL(at pos: Int) -> (contentStart: Int, contentLength: Int)? {
            guard pos < derData.count else { return nil }
            var i = pos + 1 // skip tag byte
            guard i < derData.count else { return nil }
            let firstLen = derData[i]
            i += 1
            if firstLen < 0x80 {
                return (i, Int(firstLen))
            } else {
                let numBytes = Int(firstLen & 0x7F)
                guard numBytes > 0, numBytes <= 4, i + numBytes <= derData.count else { return nil }
                var length = 0
                for j in 0..<numBytes {
                    length = (length << 8) | Int(derData[i + j])
                }
                return (i + numBytes, length)
            }
        }

        // Helper: skip one TLV element, returning offset after the element
        func skipTLV(at pos: Int) -> Int? {
            guard let (cs, cl) = readTL(at: pos) else { return nil }
            return cs + cl
        }

        // Reusable formatters for ASN.1 time parsing
        let utcTimeFormatter: DateFormatter = {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = TimeZone(identifier: "UTC")
            df.dateFormat = "yyMMddHHmmss'Z'"
            return df
        }()
        let generalizedTimeFormatter: DateFormatter = {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = TimeZone(identifier: "UTC")
            df.dateFormat = "yyyyMMddHHmmss'Z'"
            return df
        }()

        // Parse a UTCTime or GeneralizedTime value into a Date
        func parseTime(at pos: Int) -> Date? {
            guard pos < derData.count else { return nil }
            let tag = derData[pos]
            guard let (cs, cl) = readTL(at: pos), cl > 0 else { return nil }
            guard cs + cl <= derData.count else { return nil }
            let bytes = derData[cs..<(cs + cl)]
            guard let str = String(data: bytes, encoding: .ascii) else { return nil }

            if tag == 0x17 { // UTCTime  YYMMDDHHmmssZ
                return utcTimeFormatter.date(from: str)
            } else if tag == 0x18 { // GeneralizedTime  YYYYMMDDHHmmssZ
                return generalizedTimeFormatter.date(from: str)
            }
            return nil
        }

        // Outer SEQUENCE (Certificate)
        guard let (certCS, _) = readTL(at: offset) else { return nil }
        offset = certCS

        // TBSCertificate SEQUENCE
        guard derData[offset] == 0x30 else { return nil }
        guard let (tbsCS, _) = readTL(at: offset) else { return nil }
        offset = tbsCS

        // Skip optional explicit version tag [0]
        if offset < derData.count, derData[offset] == 0xA0 {
            guard let next = skipTLV(at: offset) else { return nil }
            offset = next
        }

        // Skip serialNumber (INTEGER)
        guard let afterSerial = skipTLV(at: offset) else { return nil }
        offset = afterSerial

        // Skip signature algorithm (SEQUENCE)
        guard let afterSigAlg = skipTLV(at: offset) else { return nil }
        offset = afterSigAlg

        // Skip issuer (SEQUENCE)
        guard let afterIssuer = skipTLV(at: offset) else { return nil }
        offset = afterIssuer

        // Validity SEQUENCE
        guard offset < derData.count, derData[offset] == 0x30 else { return nil }
        guard let (valCS, _) = readTL(at: offset) else { return nil }
        offset = valCS

        // notBefore — skip it
        guard let afterNotBefore = skipTLV(at: offset) else { return nil }
        offset = afterNotBefore

        // notAfter — parse it
        return parseTime(at: offset)
    }

    /// Evaluates trust for the certificate, optionally using the trust object
    /// provided by `SecPKCS12Import`.
    private static func _evaluateTrust(certificate: SecCertificate, items: [[String: Any]]) -> Bool {
        // Prefer the trust object returned by SecPKCS12Import
        let trustValue = items[0][kSecImportItemTrust as String] as AnyObject
        if CFGetTypeID(trustValue) == SecTrustGetTypeID() {
            let secTrust = trustValue as! SecTrust
            var error: CFError?
            let result = SecTrustEvaluateWithError(secTrust, &error)
            return result
        }

        // Fallback: create a basic X.509 trust evaluation
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        guard SecTrustCreateWithCertificates(certificate, policy, &trust) == errSecSuccess,
              let secTrust = trust else {
            return false
        }
        var error: CFError?
        return SecTrustEvaluateWithError(secTrust, &error)
    }
}
