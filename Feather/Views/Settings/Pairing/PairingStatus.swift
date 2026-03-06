import Foundation

// MARK: - Pairing Status
/// Represents the lifecycle state of a pairing session.
enum PairingStatus: Equatable {
    /// No active pairing session.
    case idle
    /// Generating a pairing code on the server.
    case generating
    /// Code generated; waiting for the remote device to connect.
    case waiting
    /// Both devices are connected and paired.
    case connected
    /// Pairing failed with a user-friendly message.
    case failed(String)

    static func == (lhs: PairingStatus, rhs: PairingStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.generating, .generating),
             (.waiting, .waiting), (.connected, .connected):
            return true
        case (.failed(let l), .failed(let r)):
            return l == r
        default:
            return false
        }
    }
}
