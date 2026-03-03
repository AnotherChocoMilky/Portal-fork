//
//  DebugServerClient.swift
//  Feather
//

import Foundation
import IDevice
import OSLog

// MARK: - DebugServerClient

/// Connects to the on-device debugserver via the RSD tunnel, attaches to a
/// running process, and immediately detaches to leave JIT compilation enabled.
///
/// This mirrors the `debug_app_pid` / `runDebugServerCommand` flow from StikDebug's jit.c.
class DebugServerClient {

    // MARK: - Types

    typealias CoreDeviceProxyHandle = OpaquePointer
    typealias AdapterHandle = OpaquePointer
    typealias ReadWriteOpaqueHandle = OpaquePointer
    typealias RsdHandshakeHandle = OpaquePointer
    typealias RemoteServerHandle = OpaquePointer
    typealias DebugProxyHandle = OpaquePointer
    typealias ProcessControlHandle = OpaquePointer

    // MARK: - Private state (cleaned up in `disconnect`)

    private var coreDevice: CoreDeviceProxyHandle?
    private var adapter: AdapterHandle?
    private var handshake: RsdHandshakeHandle?
    private var remoteServer: RemoteServerHandle?
    private var debugProxy: DebugProxyHandle?

    // MARK: - Init / teardown

    init() {}

    deinit {
        disconnect()
    }

    // MARK: - Public API

    /// Launches the app identified by `bundleID` in a suspended state, attaches
    /// the debugserver to the resulting PID, and detaches — enabling JIT.
    ///
    /// - Parameter bundleID: The CFBundleIdentifier of the target app.
    /// - Parameter provider:  An authenticated TCP provider from `LockdownSession`.
    /// - Throws: `JITError` on any failure in the pipeline.
    func enableJIT(for bundleID: String, provider: OpaquePointer) throws {
        Logger.jit.info("enableJIT: connecting debug session for \(bundleID)")
        try connectDebugSession(provider: provider)

        guard let remoteServer = remoteServer else {
            throw JITError.debugSessionFailed("Remote server handle is nil after connect")
        }

        // Launch app suspended → obtain PID
        Logger.jit.info("enableJIT: launching app suspended to obtain PID")
        let pid = try launchAppSuspended(bundleID: bundleID, remoteServer: remoteServer)

        Logger.jit.info("enableJIT: attaching debugserver to PID \(pid)")
        try attachAndResume(pid: pid)

        Logger.jit.info("enableJIT: JIT enabled for \(bundleID) (PID \(pid))")
        disconnect()
    }

    // MARK: - Private: debug session setup

    /// Performs the full RSD handshake sequence, mirroring `connect_debug_session` from jit.c.
    private func connectDebugSession(provider: OpaquePointer) throws {
        var coreDevicePtr: OpaquePointer?
        var err = core_device_proxy_connect(provider, &coreDevicePtr)
        if let e = err {
            let code = e.pointee.code
            idevice_error_free(e)
            throw JITError.debugSessionFailed("core_device_proxy_connect failed: \(code)")
        }
        guard let coreDevicePtr else {
            throw JITError.debugSessionFailed("core_device_proxy_connect returned nil")
        }

        var rsdPort: UInt16 = 0
        err = core_device_proxy_get_server_rsd_port(coreDevicePtr, &rsdPort)
        if let e = err {
            let code = e.pointee.code
            idevice_error_free(e)
            core_device_proxy_free(coreDevicePtr)
            throw JITError.debugSessionFailed("get_server_rsd_port failed: \(code)")
        }

        var adapterPtr: OpaquePointer?
        err = core_device_proxy_create_tcp_adapter(coreDevicePtr, &adapterPtr)
        if let e = err {
            let code = e.pointee.code
            idevice_error_free(e)
            core_device_proxy_free(coreDevicePtr)
            throw JITError.debugSessionFailed("create_tcp_adapter failed: \(code)")
        }
        // Ownership of core_device transferred to adapter
        guard let adapterPtr else {
            core_device_proxy_free(coreDevicePtr)
            throw JITError.debugSessionFailed("create_tcp_adapter returned nil adapter")
        }
        self.adapter = adapterPtr

        var streamPtr: OpaquePointer?
        err = adapter_connect(adapterPtr, rsdPort, &streamPtr)
        if let e = err {
            let code = e.pointee.code
            idevice_error_free(e)
            throw JITError.debugSessionFailed("adapter_connect failed: \(code)")
        }
        guard let streamPtr else {
            throw JITError.debugSessionFailed("adapter_connect returned nil stream")
        }

        var handshakePtr: OpaquePointer?
        err = rsd_handshake_new(streamPtr, &handshakePtr)
        if let e = err {
            let code = e.pointee.code
            idevice_error_free(e)
            // stream consumed by rsd_handshake_new on failure
            throw JITError.debugSessionFailed("rsd_handshake_new failed: \(code)")
        }
        guard let handshakePtr else {
            throw JITError.debugSessionFailed("rsd_handshake_new returned nil")
        }
        self.handshake = handshakePtr
        // stream is consumed by the handshake stack

        var remoteServerPtr: OpaquePointer?
        err = remote_server_connect_rsd(adapterPtr, handshakePtr, &remoteServerPtr)
        if let e = err {
            let code = e.pointee.code
            idevice_error_free(e)
            throw JITError.debugSessionFailed("remote_server_connect_rsd failed: \(code)")
        }
        guard let remoteServerPtr else {
            throw JITError.debugSessionFailed("remote_server_connect_rsd returned nil")
        }
        self.remoteServer = remoteServerPtr

        var debugProxyPtr: OpaquePointer?
        err = debug_proxy_connect_rsd(adapterPtr, handshakePtr, &debugProxyPtr)
        if let e = err {
            let code = e.pointee.code
            idevice_error_free(e)
            throw JITError.debugSessionFailed("debug_proxy_connect_rsd failed: \(code)")
        }
        guard let debugProxyPtr else {
            throw JITError.debugSessionFailed("debug_proxy_connect_rsd returned nil")
        }
        self.debugProxy = debugProxyPtr
    }

    // MARK: - Private: launch suspended

    /// Launches the app in a suspended state and returns its PID.
    private func launchAppSuspended(bundleID: String, remoteServer: OpaquePointer) throws -> Int64 {
        var processControl: OpaquePointer?
        var err = process_control_new(remoteServer, &processControl)
        if let e = err {
            let code = e.pointee.code
            idevice_error_free(e)
            throw JITError.pidResolutionFailed("process_control_new failed: \(code)")
        }
        guard let processControl else {
            throw JITError.pidResolutionFailed("process_control_new returned nil")
        }
        defer { process_control_free(processControl) }

        var pid: UInt64 = 0
        err = bundleID.withCString { bundleIDCStr in
            process_control_launch_app(processControl, bundleIDCStr, nil, 0, nil, 0, true, false, &pid)
        }
        if let e = err {
            let code = e.pointee.code
            idevice_error_free(e)
            throw JITError.pidResolutionFailed("process_control_launch_app failed: \(code)")
        }

        return Int64(pid)
    }

    // MARK: - Private: attach and resume

    /// Sends QStartNoAckMode, vAttach, and D (detach) to the debug proxy.
    private func attachAndResume(pid: Int64) throws {
        guard let debugProxy else {
            throw JITError.attachFailed("Debug proxy handle is nil")
        }

        // Send initial acks as required by the GDB remote serial protocol
        if let e = debug_proxy_send_ack(debugProxy) { idevice_error_free(e) }
        if let e = debug_proxy_send_ack(debugProxy) { idevice_error_free(e) }

        // Disable ack mode for efficiency
        var response: UnsafeMutablePointer<CChar>?
        let noAckCmd: UnsafeMutablePointer<DebugserverCommandHandle>? = debugserver_command_new("QStartNoAckMode", nil, 0)
        var err = debug_proxy_send_command(debugProxy, noAckCmd, &response)
        debugserver_command_free(noAckCmd)
        if let resp = response { idevice_string_free(resp); response = nil }
        if let e = err { idevice_error_free(e) } // Non-fatal; proceed

        debug_proxy_set_ack_mode(debugProxy, 0)

        // Attach to the suspended process
        let attachCmdStr = String(format: "vAttach;%llx", pid)
        let attachCmd: UnsafeMutablePointer<DebugserverCommandHandle>? = debugserver_command_new(attachCmdStr, nil, 0)
        err = debug_proxy_send_command(debugProxy, attachCmd, &response)
        debugserver_command_free(attachCmd)
        if let resp = response {
            Logger.jit.debug("vAttach response: \(String(cString: resp))")
            idevice_string_free(resp)
        }
        if let e = err {
            let code = e.pointee.code
            idevice_error_free(e)
            throw JITError.attachFailed("vAttach failed: \(code)")
        }

        // Detach — this resumes the process with JIT enabled
        let detachCmd: UnsafeMutablePointer<DebugserverCommandHandle>? = debugserver_command_new("D", nil, 0)
        err = debug_proxy_send_command(debugProxy, detachCmd, &response)
        debugserver_command_free(detachCmd)
        if let resp = response {
            Logger.jit.debug("Detach response: \(String(cString: resp))")
            idevice_string_free(resp)
        }
        if let e = err {
            // Log but don't throw — detach errors after successful attach still enable JIT
            Logger.jit.warning("Detach error (non-fatal): \(e.pointee.code)")
            idevice_error_free(e)
        }
    }

    // MARK: - Disconnect / cleanup

    func disconnect() {
        if let dp = debugProxy { debug_proxy_free(dp); debugProxy = nil }
        if let rs = remoteServer { remote_server_free(rs); remoteServer = nil }
        if let hs = handshake { rsd_handshake_free(hs); handshake = nil }
        if let ad = adapter { adapter_free(ad); adapter = nil }
        // coreDevice ownership was transferred to adapter; do not free separately
        coreDevice = nil
    }
}
