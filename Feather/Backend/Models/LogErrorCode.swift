import Foundation

struct LogErrorCodeInfo: Identifiable {
    let id = UUID()
    let code: String
    let description: String
    let suggestion: String
}

enum LogErrorCode: String, CaseIterable {
    // General
    case GEN_001 = "ERR-GEN-001" // Unexpected Error
    case GEN_002 = "ERR-GEN-002" // Permission Denied

    // Signing
    case SIGN_001 = "ERR-SIGN-001" // Signing Failed
    case SIGN_002 = "ERR-SIGN-002" // Certificate Expired
    case SIGN_003 = "ERR-SIGN-003" // Missing Certificate
    case SIGN_004 = "ERR-SIGN-004" // Provisioning Profile Error

    // Network
    case NET_001 = "ERR-NET-001" // Connection Failed
    case NET_002 = "ERR-NET-002" // Request Timed Out
    case NET_003 = "ERR-NET-003" // Invalid Source URL

    // Storage
    case STR_001 = "ERR-STR-001" // Out of Storage
    case STR_002 = "ERR-STR-002" // Database Corruption
    case STR_003 = "ERR-STR-003" // File Not Found

    // IPA
    case IPA_001 = "ERR-IPA-001" // Invalid IPA Format
    case IPA_002 = "ERR-IPA-002" // Extraction Failed
    case IPA_003 = "ERR-IPA-003" // Missing Info.plist

    var info: LogErrorCodeInfo {
        switch self {
        case .GEN_001:
            return LogErrorCodeInfo(code: self.rawValue, description: "An unexpected error occurred in the application.", suggestion: "Try restarting the app or checking other logs for more context.")
        case .GEN_002:
            return LogErrorCodeInfo(code: self.rawValue, description: "The app does not have permission to perform this action.", suggestion: "Check iOS Settings and ensure Portal has all necessary permissions.")

        case .SIGN_001:
            return LogErrorCodeInfo(code: self.rawValue, description: "The code signing process failed.", suggestion: "Ensure your certificate and provisioning profile are valid and compatible.")
        case .SIGN_002:
            return LogErrorCodeInfo(code: self.rawValue, description: "The selected certificate has expired.", suggestion: "Use a new certificate or renew your current one via Apple Developer Portal.")
        case .SIGN_003:
            return LogErrorCodeInfo(code: self.rawValue, description: "No signing certificate was provided for the operation.", suggestion: "Import a P12 or use a Portal-connected developer account.")
        case .SIGN_004:
            return LogErrorCodeInfo(code: self.rawValue, description: "There is an issue with the provisioning profile.", suggestion: "Check if the profile matches the bundle identifier and certificate.")

        case .NET_001:
            return LogErrorCodeInfo(code: self.rawValue, description: "Failed to connect to the server.", suggestion: "Check your internet connection or VPN settings.")
        case .NET_002:
            return LogErrorCodeInfo(code: self.rawValue, description: "The network request timed out.", suggestion: "Try again later or check if the source server is down.")
        case .NET_003:
            return LogErrorCodeInfo(code: self.rawValue, description: "The source URL is invalid or malformed.", suggestion: "Verify the URL and ensure it points to a valid AltStore/Scarlet source.")

        case .STR_001:
            return LogErrorCodeInfo(code: self.rawValue, description: "The device is out of storage space.", suggestion: "Free up some space by deleting unused apps or files.")
        case .STR_002:
            return LogErrorCodeInfo(code: self.rawValue, description: "The local database appears to be corrupted.", suggestion: "Export your data if possible, then try resetting the app.")
        case .STR_003:
            return LogErrorCodeInfo(code: self.rawValue, description: "The requested file could not be found.", suggestion: "Ensure the file hasn't been moved or deleted manually.")

        case .IPA_001:
            return LogErrorCodeInfo(code: self.rawValue, description: "The IPA file format is invalid or corrupted.", suggestion: "Try redownloading the IPA from a reliable source.")
        case .IPA_002:
            return LogErrorCodeInfo(code: self.rawValue, description: "Failed to extract the app bundle from the IPA.", suggestion: "Ensure you have enough storage and the IPA is not encrypted.")
        case .IPA_003:
            return LogErrorCodeInfo(code: self.rawValue, description: "The app bundle is missing its Info.plist file.", suggestion: "This IPA may be malformed. Try a different version of the app.")
        }
    }
}
