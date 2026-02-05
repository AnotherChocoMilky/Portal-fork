import ActivityKit
import Foundation
import SwiftUI

/// Activity attributes for app installation Live Activity
@available(iOS 16.1, *)
struct InstallationActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic properties that can be updated
        var progress: Double
        var bytesDownloaded: Int64
        var totalBytes: Int64
        var status: InstallationStatus
        var timeRemaining: TimeInterval?
        
        var progressPercentage: String {
            String(format: "%.0f%%", progress * 100)
        }
        
        var formattedBytesDownloaded: String {
            ByteCountFormatter.string(fromByteCount: bytesDownloaded, countStyle: .file)
        }
        
        var formattedTotalBytes: String {
            ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        }
        
        var formattedTimeRemaining: String? {
            guard let time = timeRemaining else { return nil }
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.unitsStyle = .abbreviated
            formatter.maximumUnitCount = 2
            return formatter.string(from: time)
        }
    }
    
    // Static properties that don't change
    var appName: String
    var appBundleId: String
    var appIcon: Data?
    var startTime: Date
}

/// Installation status enum for Live Activity
enum InstallationStatus: String, Codable, Hashable {
    case downloading = "Downloading"
    case installing = "Installing"
    case verifying = "Verifying"
    case completed = "Completed"
    case failed = "Failed"
    case paused = "Paused"
    
    var icon: String {
        switch self {
        case .downloading: return "arrow.down.circle.fill"
        case .installing: return "gear.circle.fill"
        case .verifying: return "checkmark.shield.fill"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .paused: return "pause.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .downloading: return .blue
        case .installing: return .purple
        case .verifying: return .orange
        case .completed: return .green
        case .failed: return .red
        case .paused: return .yellow
        }
    }
}
