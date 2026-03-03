//
//  JITFallbackProtocol.swift
//  Feather
//

import Foundation
import OSLog

// MARK: - JITFallbackStrategy

/// A single recoverable strategy executed by JITManager when an attach failure occurs.
/// Every strategy must be fully self-contained and throw structured JITError values.
protocol JITFallbackStrategy {
    /// Stable machine identifier used for UserDefaults persistence and registry lookup.
    var identifier: String { get }
    /// Human-readable name shown in JITSettingsView.
    var displayName: String { get }
    /// Short description of what the strategy does, shown as footer text.
    var strategyDescription: String { get }
    /// Executes the fallback logic using the provided context.
    /// - Parameter context: All runtime data needed for recovery.
    /// - Throws: `JITError` if recovery was unsuccessful.
    func execute(context: JITContext) async throws
}

// MARK: - JITContext

/// All runtime data required by a fallback strategy to attempt recovery.
struct JITContext {
    /// Bundle identifier of the target app.
    let bundleID: String
    /// PID resolved before the attach failure. May be re-resolved by strategies.
    var currentPID: Int64
    /// Active lockdown session. Strategies may disconnect and reconnect it.
    let lockdownSession: LockdownSession
    /// VPN manager reference, used if the strategy needs to verify tunnel state.
    let vpnManager: TunnelManager
    /// Shared logger for structured log output.
    let logger: Logger
}
