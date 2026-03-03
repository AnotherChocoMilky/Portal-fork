//
//  JITError.swift
//  Feather
//

import Foundation

// MARK: - JITError

/// Structured error type for the entire JIT enabling pipeline.
enum JITError: LocalizedError {
    case pairingFileNotFound
    case pairingFileInvalid(String)
    case vpnNotActive
    case socketConnectionFailed(String)
    case debugSessionFailed(String)
    case pidResolutionFailed(String)
    case attachFailed(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .pairingFileNotFound:
            return String.localized("Pairing file not found. Please import a valid pairing file.")
        case .pairingFileInvalid(let detail):
            return String.localized("Pairing file is invalid: \(detail)")
        case .vpnNotActive:
            return String.localized("VPN tunnel is not active. Please enable LocalDevVPN.")
        case .socketConnectionFailed(let detail):
            return String.localized("Cannot connect to device: \(detail)")
        case .debugSessionFailed(let detail):
            return String.localized("Debug session failed: \(detail)")
        case .pidResolutionFailed(let detail):
            return String.localized("Failed to resolve PID: \(detail)")
        case .attachFailed(let detail):
            return String.localized("Attach failed: \(detail)")
        case .unknown(let detail):
            return String.localized("Unknown error: \(detail)")
        }
    }
}
