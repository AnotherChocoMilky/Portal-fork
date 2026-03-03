//
//  JITError.swift
//  Feather
//

import Foundation

// MARK: - JITError

/// Structured error type for the entire JIT enabling pipeline.
enum JITError: LocalizedError {
    case unsupportedIOSVersion(String)
    case pairingMissing
    case pairingInvalid(String)
    case vpnStartFailed(String)
    case lockdownAuthenticationFailed(String)
    case debugServerStartFailed(String)
    case processNotRunning(String)
    case attachFailed(String)
    case resumeFailed(String)
    case timeout
    case unknownError(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedIOSVersion(let version):
            return String.localized("iOS \(version) is not supported for JIT. Please use iOS 17.4 or newer.")
        case .pairingMissing:
            return String.localized("Pairing record is missing. Please import your device's pairing file.")
        case .pairingInvalid(let detail):
            return String.localized("Pairing record is invalid: \(detail)")
        case .vpnStartFailed(let detail):
            return String.localized("Failed to start loopback VPN: \(detail)")
        case .lockdownAuthenticationFailed(let detail):
            return String.localized("Lockdown authentication failed: \(detail)")
        case .debugServerStartFailed(let detail):
            return String.localized("Failed to start debugserver service: \(detail)")
        case .processNotRunning(let bundleID):
            return String.localized("Process '\(bundleID)' is not running or could not be resolved.")
        case .attachFailed(let detail):
            return String.localized("Failed to attach debugserver: \(detail)")
        case .resumeFailed(let detail):
            return String.localized("Failed to resume process: \(detail)")
        case .timeout:
            return String.localized("The operation timed out.")
        case .unknownError(let detail):
            return String.localized("An unknown error occurred: \(detail)")
        }
    }
}
