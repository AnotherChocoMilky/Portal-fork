//
//  JITFallbackRegistry.swift
//  Feather
//

import Foundation

// MARK: - JITFallbackRegistry

/// Central registry that exposes all available fallback strategies for UI selection
/// and JITManager execution. Add new strategies here to make them available everywhere.
class JITFallbackRegistry {

    /// All strategies available for selection in JITSettingsView.
    /// The first entry is used as the default when no selection has been persisted.
    static let availableStrategies: [any JITFallbackStrategy] = [
        RetryAttachStrategy(),
        PIDRevalidationStrategy(),
        LockdownResetStrategy(),
        DelayedAttachStrategy()
    ]
}
