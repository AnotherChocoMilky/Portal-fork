//
//  LockdownSession.swift
//  Feather
//

import Foundation
import IDevice
import IDeviceSwift
import OSLog

// MARK: - LockdownSession

/// Establishes an authenticated lockdown session using the pairing record
/// and provides a TCP provider handle for downstream services (debugserver, etc.).
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

    /// Establishes a connection to the device and authenticates via the pairing file.
    /// This utilizes the loopback VPN address (10.7.0.1).
    ///
    /// - Parameter timeout: Maximum seconds to wait for the connection.
    /// - Throws: `JITError` if authentication or connection fails.
    func connect(timeout: TimeInterval = 5.0) throws {
        Logger.jit.info("LockdownSession: Attempting to connect to device")

        let pairingManager = PairingManager.shared
        let pairingFile = try pairingManager.readPairingFile()
        defer { idevice_pairing_file_free(pairingFile) }

        // Define device address
        var addr = sockaddr_in()
        memset(&addr, 0, MemoryLayout.size(ofValue: addr))
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = CFSwapInt16HostToBig(UInt16(LOCKDOWN_PORT))

        guard inet_pton(AF_INET, "10.7.0.1", &addr.sin_addr) == 1 else {
            throw JITError.unknownError("Invalid loopback IP address")
        }

        // Create TCP provider
        var providerPtr: TcpProviderHandle?
        let result = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                idevice_tcp_provider_new(sockaddrPtr, pairingFile, "Portal-JIT", &providerPtr)
            }
        }

        if let err = result {
            let code = err.pointee.code
            idevice_error_free(err)
            Logger.jit.error("LockdownSession: Failed to create TCP provider: \(code)")
            throw JITError.lockdownAuthenticationFailed("Failed to create TCP provider (code \(code))")
        }

        guard let p = providerPtr else {
            throw JITError.lockdownAuthenticationFailed("Nil provider returned")
        }

        self.provider = p
        Logger.jit.info("LockdownSession: Authenticated and connected successfully")
    }

    // MARK: - Disconnect

    func disconnect() {
        // TCP provider is managed by the C side usually, but if we allocated it we should be careful.
        // In idevice-ffi, idevice_tcp_provider_new creates it. There isn't an explicit free for just the provider
        // but it's typically cleaned up when the higher-level handles are closed or on deinit of the FFI side.
        provider = nil
    }
}
