//
//  ProcessResolver.swift
//  Feather
//

import Foundation
import IDevice
import OSLog

// MARK: - ProcessResolver

/// Resolves the PID of an installed application from its bundle identifier.
///
/// The reliable approach used by StikDebug is to launch the app in a suspended
/// state via `process_control_launch_app` — this guarantees a PID even for apps
/// that are not currently running, and avoids fragile heuristics.
///
/// The `DebugServerClient` subsequently attaches the debugserver to this PID and
/// detaches, which resumes execution with JIT enabled.
class ProcessResolver {

    // MARK: - Singleton

    static let shared = ProcessResolver()
    private init() {}

    // MARK: - Public API

    /// Returns the PID for the given bundle ID by launching the app suspended.
    ///
    /// This is a lightweight wrapper; the actual launch happens inside
    /// `DebugServerClient.enableJIT(for:provider:)` which both launches and
    /// attaches in a single session. Use this method only when you need the PID
    /// without intending to attach immediately.
    ///
    /// - Parameters:
    ///   - bundleID: The CFBundleIdentifier of the target app.
    ///   - provider:  An authenticated TCP provider from `LockdownSession`.
    /// - Returns: The PID of the launched (suspended) process.
    /// - Throws: `JITError.pidResolutionFailed` on failure.
    func resolvePID(for bundleID: String, provider: OpaquePointer) throws -> Int64 {
        // We need a full RSD session to use process_control
        let remoteServer = try openRemoteServer(provider: provider)
        defer { remote_server_free(remoteServer) }

        var processControl: OpaquePointer?
        let pcErr = process_control_new(remoteServer, &processControl)
        if let e = pcErr {
            let code = e.pointee.code
            idevice_error_free(e)
            throw JITError.pidResolutionFailed("process_control_new failed: \(code)")
        }
        guard let processControl else {
            throw JITError.pidResolutionFailed("process_control_new returned nil")
        }
        defer { process_control_free(processControl) }

        var pid: UInt64 = 0
        let launchErr = bundleID.withCString { cStr in
            process_control_launch_app(processControl, cStr, nil, 0, nil, 0, true, false, &pid)
        }
        if let e = launchErr {
            let code = e.pointee.code
            idevice_error_free(e)
            throw JITError.pidResolutionFailed("process_control_launch_app failed: \(code)")
        }

        Logger.jit.info("ProcessResolver: resolved PID \(pid) for \(bundleID)")
        return Int64(pid)
    }

    // MARK: - Private helpers

    /// Opens a minimal RSD remote server session sufficient for process_control.
    private func openRemoteServer(provider: OpaquePointer) throws -> OpaquePointer {
        var coreDevice: OpaquePointer?
        var err = core_device_proxy_connect(provider, &coreDevice)
        if let e = err {
            let code = e.pointee.code
            idevice_error_free(e)
            throw JITError.pidResolutionFailed("core_device_proxy_connect failed: \(code)")
        }
        guard let coreDevice else {
            throw JITError.pidResolutionFailed("core_device_proxy_connect returned nil")
        }

        var rsdPort: UInt16 = 0
        err = core_device_proxy_get_server_rsd_port(coreDevice, &rsdPort)
        if let e = err {
            let code = e.pointee.code
            idevice_error_free(e)
            core_device_proxy_free(coreDevice)
            throw JITError.pidResolutionFailed("get_server_rsd_port failed: \(code)")
        }

        var adapter: OpaquePointer?
        err = core_device_proxy_create_tcp_adapter(coreDevice, &adapter)
        if let e = err {
            let code = e.pointee.code
            idevice_error_free(e)
            core_device_proxy_free(coreDevice)
            throw JITError.pidResolutionFailed("create_tcp_adapter failed: \(code)")
        }
        guard let adapter else {
            core_device_proxy_free(coreDevice)
            throw JITError.pidResolutionFailed("create_tcp_adapter returned nil")
        }
        // Ownership transferred to adapter

        var stream: OpaquePointer?
        err = adapter_connect(adapter, rsdPort, &stream)
        if let e = err {
            let code = e.pointee.code
            idevice_error_free(e)
            adapter_free(adapter)
            throw JITError.pidResolutionFailed("adapter_connect failed: \(code)")
        }
        guard let stream else {
            adapter_free(adapter)
            throw JITError.pidResolutionFailed("adapter_connect returned nil stream")
        }

        var handshake: OpaquePointer?
        err = rsd_handshake_new(stream, &handshake)
        if let e = err {
            let code = e.pointee.code
            idevice_error_free(e)
            adapter_free(adapter)
            throw JITError.pidResolutionFailed("rsd_handshake_new failed: \(code)")
        }
        guard let handshake else {
            adapter_free(adapter)
            throw JITError.pidResolutionFailed("rsd_handshake_new returned nil")
        }

        var remoteServer: OpaquePointer?
        err = remote_server_connect_rsd(adapter, handshake, &remoteServer)
        if let e = err {
            let code = e.pointee.code
            idevice_error_free(e)
            rsd_handshake_free(handshake)
            adapter_free(adapter)
            throw JITError.pidResolutionFailed("remote_server_connect_rsd failed: \(code)")
        }
        guard let remoteServer else {
            rsd_handshake_free(handshake)
            adapter_free(adapter)
            throw JITError.pidResolutionFailed("remote_server_connect_rsd returned nil")
        }

        // handshake and adapter lifetime managed by remoteServer/debugProxy
        return remoteServer
    }
}
