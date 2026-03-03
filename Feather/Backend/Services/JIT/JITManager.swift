//
//  JITManager.swift
//  Feather
//

import Foundation
import IDevice
import IDeviceSwift
import Network
import OSLog

// MARK: - JITManager

/// High-level orchestrator for the JIT enabling pipeline.
///
/// Usage:
/// ```swift
/// let result = await JITManager.shared.enableJIT(for: "com.example.app")
/// ```
@MainActor
class JITManager: ObservableObject {

    // MARK: - Singleton

    static let shared = JITManager()
    private init() {}

    // MARK: - Published state (drives JITStatusView)

    @Published var state: JITState = .idle
    @Published var lastError: JITError?

    // MARK: - Dependencies

    private let pairingManager = PairingManager.shared
    private let lockdownSession = LockdownSession()

    // MARK: - Public API

    /// Enables JIT for the application with the given bundle identifier.
    ///
    /// Steps:
    /// 1. Validate pairing file
    /// 2. Check VPN / socket connectivity
    /// 3. Establish lockdown session (obtain TCP provider)
    /// 4. Construct a `DebugServerClient` and run the full attach flow
    ///
    /// - Parameter bundleID: The CFBundleIdentifier of the target app.
    /// - Returns: `true` on success, `false` on failure (error stored in `lastError`).
    @discardableResult
    func enableJIT(for bundleID: String) async -> Bool {
        lastError = nil
        state = .validatingPairing

        do {
            // 1. Pairing file
            guard pairingManager.hasPairingFile else {
                throw JITError.pairingFileNotFound
            }
            guard pairingManager.validatePairingFile() else {
                throw JITError.pairingFileInvalid("Could not parse the pairing file")
            }

            // 2. VPN / socket connectivity
            state = .checkingVPN
            let socketCheck = await checkSocketOnBackground()
            guard socketCheck.isConnected else {
                throw JITError.vpnNotActive
            }

            // 3. Lockdown / TCP provider
            state = .connectingLockdown
            try lockdownSession.connect()
            guard let provider = lockdownSession.provider else {
                throw JITError.debugSessionFailed("No TCP provider after lockdown connect")
            }

            // 4. Attach debugserver
            state = .connectingDebugServer
            try await attachDebugServerOnBackground(bundleID: bundleID, provider: provider)

            state = .jitEnabled
            return true

        } catch let error as JITError {
            lastError = error
            state = .failed(error)
            Logger.jit.error("enableJIT failed: \(error.localizedDescription ?? "unknown")")
            return false
        } catch {
            let wrappedError = JITError.unknown(error.localizedDescription)
            lastError = wrappedError
            state = .failed(wrappedError)
            Logger.jit.error("enableJIT unexpected error: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Background helpers

    private func checkSocketOnBackground() async -> (isConnected: Bool, error: String?) {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = HeartbeatManager.shared.checkSocketConnection()
                continuation.resume(returning: result)
            }
        }
    }

    private func attachDebugServerOnBackground(bundleID: String, provider: OpaquePointer) async throws {
        try await Task.detached(priority: .userInitiated) {
            let client = DebugServerClient()
            try client.enableJIT(for: bundleID, provider: provider)
        }.value
    }
}

// MARK: - JITState

enum JITState: Equatable {
    case idle
    case validatingPairing
    case checkingVPN
    case connectingLockdown
    case connectingDebugServer
    case jitEnabled
    case failed(JITError)

    static func == (lhs: JITState, rhs: JITState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.validatingPairing, .validatingPairing),
             (.checkingVPN, .checkingVPN),
             (.connectingLockdown, .connectingLockdown),
             (.connectingDebugServer, .connectingDebugServer),
             (.jitEnabled, .jitEnabled):
            return true
        case (.failed(let a), .failed(let b)):
            return a.localizedDescription == b.localizedDescription
        default:
            return false
        }
    }

    var displayTitle: String {
        switch self {
        case .idle:                  return String.localized("Ready")
        case .validatingPairing:     return String.localized("Validating Pairing File...")
        case .checkingVPN:           return String.localized("Checking VPN Tunnel...")
        case .connectingLockdown:    return String.localized("Connecting to Device...")
        case .connectingDebugServer: return String.localized("Attaching Debugserver...")
        case .jitEnabled:            return String.localized("JIT Enabled!")
        case .failed:                return String.localized("Failed")
        }
    }

    var isInProgress: Bool {
        switch self {
        case .validatingPairing, .checkingVPN, .connectingLockdown, .connectingDebugServer:
            return true
        default:
            return false
        }
    }
}
