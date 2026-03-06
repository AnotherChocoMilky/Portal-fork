import Foundation
import SwiftUI
import NimbleViews

// MARK: - Pairing Error
enum PairingError: Error {
    case serverError(String)
    case timeout
    case networkUnavailable

    var userMessage: String {
        switch self {
        case .serverError(let reason):
            return reason.isEmpty
                ? .localized("Something went wrong. Please try again.")
                : reason
        case .timeout:
            return .localized("Pairing timed out. Please try again.")
        case .networkUnavailable:
            return .localized("No network connection. Please check your connection.")
        }
    }
}

// MARK: - Pairing View Model
/// Manages the full lifecycle of a device-pairing session.
/// `progress` (0…1) drives both the sphere morph animation and the UI
/// progress indicator.
@MainActor
class PairingViewModel: ObservableObject {

    // MARK: - Published State

    @Published var status: PairingStatus = .idle
    /// Morph progress: 0 = full chaos, 1 = perfect Fibonacci sphere.
    @Published var progress: Double = 0.0
    @Published var generatedCode: String? = nil
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false

    // MARK: - Private

    private var pollingTask: Task<Void, Never>?
    private var progressTask: Task<Void, Never>?
    private let service = PairingService.shared

    // MARK: - Computed Properties

    var canRetry: Bool {
        if case .failed = status { return true }
        return false
    }

    var statusMessage: String {
        switch status {
        case .idle:
            return .localized("Ready to pair devices")
        case .generating:
            return .localized("Generating pairing code…")
        case .waiting:
            return .localized("Waiting for the other device to connect…")
        case .connected:
            return .localized("Devices connected successfully!")
        case .failed(let reason):
            return reason
        }
    }

    // MARK: - Actions

    /// Starts the full pairing flow: code generation → waiting → connected.
    func startGenerating() {
        guard status == .idle || canRetry else { return }
        reset()
        status = .generating
        isLoading = true

        // Animate sphere to 30% while the code is being generated
        animateProgress(to: 0.30, duration: 0.8)

        Task {
            do {
                let code = try await service.generatePairingCode()
                generatedCode = code
                status = .waiting
                isLoading = false

                // Animate sphere to 70% while waiting for the remote device
                animateProgress(to: 0.70, duration: 1.5)
                startPolling(code: code)
            } catch {
                handleError(error)
            }
        }
    }

    /// Manually marks the pairing as connected (e.g. after a UI confirmation).
    func confirmConnected() {
        pollingTask?.cancel()
        progressTask?.cancel()
        status = .connected
        // Snap sphere to fully ordered state
        withAnimation(.easeInOut(duration: 0.8)) {
            progress = 1.0
        }
    }

    /// Retries the pairing flow after a failure.
    func retry() {
        reset()
        startGenerating()
    }

    /// Cancels any in-progress pairing and returns to idle.
    func cancel() {
        pollingTask?.cancel()
        progressTask?.cancel()
        Task { await service.cancelPairing() }
        reset()
    }

    // MARK: - Private Helpers

    private func reset() {
        pollingTask?.cancel()
        progressTask?.cancel()
        status = .idle
        progress = 0.0
        generatedCode = nil
        errorMessage = nil
        isLoading = false
    }

    /// Polls `PairingService.checkStatus` every 3 s until connected or failed.
    private func startPolling(code: String) {
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled {
                do {
                    let result = try await service.checkStatus(code: code)
                    switch result {
                    case .connected:
                        confirmConnected()
                        return
                    case .failed(let reason):
                        handleError(PairingError.serverError(reason))
                        return
                    default:
                        break
                    }
                } catch {
                    if !Task.isCancelled {
                        handleError(error)
                        return
                    }
                }
                // Wait before the next poll
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }

    /// Smoothly animates `progress` toward `target` over `duration` seconds.
    private func animateProgress(to target: Double, duration: Double) {
        progressTask?.cancel()
        let start = progress
        let startTime = Date()

        progressTask = Task {
            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(startTime)
                let t = min(elapsed / duration, 1.0)
                // Ease-out cubic for a smooth landing
                let eased = 1.0 - pow(1.0 - t, 3.0)
                progress = start + (target - start) * eased
                if t >= 1.0 { break }
                try? await Task.sleep(nanoseconds: 16_000_000) // ~60 fps
            }
        }
    }

    private func handleError(_ error: Error) {
        isLoading = false
        let msg: String
        if let pErr = error as? PairingError {
            msg = pErr.userMessage
        } else {
            msg = .localized("Something went wrong. Please try again.")
        }
        errorMessage = msg
        status = .failed(msg)
        animateProgress(to: 0.0, duration: 0.6)
    }
}
