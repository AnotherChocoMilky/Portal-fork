import Foundation

// MARK: - Pairing Service
/// Async service that manages the pairing session lifecycle.
/// All methods run on their own async context via the `actor` model.
/// Real networking / server logic should replace the stubs below.
actor PairingService {

    static let shared = PairingService()
    private init() {}

    // MARK: - Generate Code

    /// Generates a random 6-digit pairing code and returns it.
    /// In a real implementation this would contact a relay server and
    /// receive a server-issued code.
    func generatePairingCode() async throws -> String {
        // Simulate server round-trip latency
        try await Task.sleep(nanoseconds: 800_000_000)
        return String(format: "%06d", Int.random(in: 0...999_999))
    }

    // MARK: - Start Pairing

    /// Begins the active pairing handshake for the given `code`.
    /// Stubs a short delay representing the initial handshake phase.
    func startPairing(code: String) async throws {
        try await Task.sleep(nanoseconds: 1_200_000_000)
    }

    // MARK: - Poll Status

    /// Polls the server for the current pairing status of the given `code`.
    /// Returns `.waiting` until the remote device connects.
    func checkStatus(code: String) async throws -> PairingStatus {
        try await Task.sleep(nanoseconds: 500_000_000)
        // Stub: always return .waiting (real impl would query a server)
        return .waiting
    }

    // MARK: - Cancel

    /// Cancels any in-progress pairing session and cleans up server state.
    func cancelPairing() async {
        // Stub: cancel in-flight network requests and invalidate the code
    }

    // MARK: - Validate

    /// Returns `true` if the provided `code` is a valid 6-digit number.
    func validateCode(_ code: String) async throws -> Bool {
        try await Task.sleep(nanoseconds: 300_000_000)
        return code.count == 6 && code.allSatisfy(\.isNumber)
    }
}
