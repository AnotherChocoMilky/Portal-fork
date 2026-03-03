//
//  JITManager.swift
//  Feather
//

import Foundation
import UIKit
import OSLog

// MARK: - JITManager

/// High-level orchestrator for the JIT enabling pipeline.
@MainActor
class JITManager: ObservableObject {

    // MARK: - Singleton

    static let shared = JITManager()
    private init() {}

    // MARK: - Published state

    @Published var state: JITState = .idle
    @Published var lastError: JITError?

    // MARK: - Fallback strategy

    /// Whether the device is running iOS 26.4 or later, requiring the automatic fallback.
    var isIOS264OrLater: Bool {
        let version = UIDevice.current.systemVersion
        let components = version.split(separator: ".").compactMap { Int($0) }
        guard components.count >= 2 else { return false }
        let major = components[0]
        let minor = components[1]
        return major > 26 || (major == 26 && minor >= 4)
    }

    /// Persisted identifier of the selected fallback strategy.
    /// Defaults to `RetryAttachStrategy` when no selection has been saved.
    /// Automatically overridden to `iOS_26_4_JIT_Method` on iOS 26.4+.
    @Published var selectedFallbackStrategyIdentifier: String = UserDefaults.standard.string(forKey: "Feather.jitFallbackStrategy") ?? "retry-attach" {
        didSet { UserDefaults.standard.set(selectedFallbackStrategyIdentifier, forKey: "Feather.jitFallbackStrategy") }
    }

    /// The active fallback strategy resolved from the registry.
    /// On iOS 26.4+, always returns `iOS_26_4_JIT_Method` regardless of user selection.
    var selectedFallbackStrategy: any JITFallbackStrategy {
        if isIOS264OrLater {
            return JITFallbackRegistry.availableStrategies.first { $0.identifier == "iOS_26_4_JIT_Method" }
                ?? JITFallbackRegistry.availableStrategies[0]
        }
        return JITFallbackRegistry.availableStrategies.first { $0.identifier == selectedFallbackStrategyIdentifier }
            ?? JITFallbackRegistry.availableStrategies[0]
    }

    // MARK: - Dependencies

    private let pairingManager = PairingManager.shared
    private let tunnelManager = TunnelManager.shared

    // MARK: - Public API

    /// Enables JIT for the application with the given bundle identifier.
    ///
    /// The flow:
    /// 1. Validate iOS version (>= 17.4)
    /// 2. Ensure loopback VPN is active
    /// 3. Validate pairing record
    /// 4. Establish lockdown session
    /// 5. Start debugserver service
    /// 6. Resolve PID by launching app suspended
    /// 7. Attach and Resume (detach)
    ///
    /// - Parameter bundleID: The CFBundleIdentifier of the target app.
    /// - Throws: `JITError` on failure.
    func enableJIT(for bundleID: String) async throws {
        lastError = nil
        Logger.jit.info("JITManager: Starting JIT pipeline for \(bundleID)")

        do {
            // 1. Validate iOS Version (fatal — no fallback)
            try validateIOSVersion()

            // 2. Ensure VPN is active
            state = .checkingVPN
            try await tunnelManager.ensureTunnelActive()

            // 3. Validate Pairing (fatal — no fallback)
            state = .validatingPairing
            guard pairingManager.hasPairingFile else {
                throw JITError.pairingMissing
            }
            guard pairingManager.validatePairingFile() else {
                throw JITError.pairingInvalid
            }

            // 4. Lockdown Session
            state = .connectingLockdown
            let lockdown = LockdownSession()
            try lockdown.connect()
            guard let provider = lockdown.provider else {
                throw JITError.lockdownAuthenticationFailed
            }

            // 5 & 6. Resolve PID (Launch Suspended)
            state = .connectingDebugServer
            let pid = try ProcessResolver.shared.launchSuspended(bundleID: bundleID, provider: provider)

            // 7. Attach and Resume — attempt primary, then fallback on recoverable errors
            let client = DebugServerClient()
            do {
                try client.attachAndEnableJIT(pid: pid, provider: provider)
            } catch let attachError as JITError where attachError.isRecoverable {
                Logger.jit.warning("JITManager: Primary attach failed (\(attachError.localizedDescription)); invoking fallback strategy '\(self.selectedFallbackStrategy.identifier)'")
                let context = JITContext(
                    bundleID: bundleID,
                    currentPID: pid,
                    lockdownSession: lockdown,
                    vpnManager: tunnelManager,
                    logger: Logger.jit
                )
                try await selectedFallbackStrategy.execute(context: context)
            }

            state = .jitEnabled
            Logger.jit.info("JITManager: JIT successfully enabled for \(bundleID)")

        } catch let error as JITError {
            lastError = error
            state = .failed(error)
            Logger.jit.error("JITManager: Pipeline failed: \(error.localizedDescription)")
            throw error
        } catch {
            let wrappedError = JITError.unknown(error.localizedDescription)
            lastError = wrappedError
            state = .failed(wrappedError)
            Logger.jit.error("JITManager: Unexpected error: \(error.localizedDescription)")
            throw wrappedError
        }
    }

    // MARK: - Helpers

    private func validateIOSVersion() throws {
        let version = UIDevice.current.systemVersion
        Logger.jit.info("JITManager: Device iOS version: \(version)")

        let components = version.split(separator: ".").compactMap { Int($0) }
        guard components.count >= 2 else {
            throw JITError.unsupportedIOSVersion(current: version)
        }

        let major = components[0]
        let minor = components[1]

        if major < 17 || (major == 17 && minor < 4) {
            throw JITError.unsupportedIOSVersion(current: version)
        }
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
        case .validatingPairing:     return String.localized("Validating Pairing Record...")
        case .checkingVPN:           return String.localized("Activating Loopback VPN...")
        case .connectingLockdown:    return String.localized("Authenticating with Device...")
        case .connectingDebugServer: return String.localized("Enabling JIT...")
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
