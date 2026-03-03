//
//  LockdownSession.swift
//  Feather
//

import Foundation
import IDevice
import IDeviceSwift

// MARK: - LockdownSession

/// Establishes an authenticated lockdown session using the pairing record
/// and provides a TCP provider handle for downstream services (debugserver, etc.).
///
/// Internally this wraps the HeartbeatManager's existing provider so that
/// JIT operations can reuse the already-authenticated connection without
/// opening a second lockdown session.
class LockdownSession {

    // MARK: - Types

    typealias TcpProviderHandle = OpaquePointer

    // MARK: - Properties

    /// The TCP provider used for all idevice service connections.
    private(set) var provider: TcpProviderHandle?

    // MARK: - Init / teardown

    init() {}

    deinit {
        disconnect()
    }

    // MARK: - Connect

    /// Borrows the provider that the HeartbeatManager has already authenticated.
    /// If the heartbeat is not running yet, this will attempt to start it and
    /// wait up to `timeout` seconds for the connection to come up.
    ///
    /// - Parameter timeout: Maximum seconds to wait for the connection.
    /// - Throws: `JITError.socketConnectionFailed` if the device cannot be reached.
    func connect(timeout: TimeInterval = 5.0) throws {
        let heartbeat = HeartbeatManager.shared

        // Quick path – provider already exists
        if let existingProvider = heartbeat.provider {
            self.provider = existingProvider
            return
        }

        // Ensure socket is reachable before bothering to start heartbeat
        let socketCheck = heartbeat.checkSocketConnection(timeoutInSeconds: timeout)
        guard socketCheck.isConnected else {
            throw JITError.socketConnectionFailed(socketCheck.error ?? "Unreachable")
        }

        // Start heartbeat and wait briefly for provider to become available
        heartbeat.start()
        let deadline = Date(timeIntervalSinceNow: timeout)
        while heartbeat.provider == nil && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.1)
        }

        guard let p = heartbeat.provider else {
            throw JITError.socketConnectionFailed("Heartbeat did not produce a provider in time")
        }
        self.provider = p
    }

    // MARK: - Disconnect

    func disconnect() {
        // We only borrow the provider from HeartbeatManager; do not free it here.
        provider = nil
    }
}
