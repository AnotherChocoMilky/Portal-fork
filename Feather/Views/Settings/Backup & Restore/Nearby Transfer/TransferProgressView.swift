import SwiftUI

// MARK: - Transfer Progress View
struct TransferProgressView: View {
    @ObservedObject var service: NearbyTransferService
    let onCancel: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Status Icon
            statusIcon
            
            // Progress Information
            switch service.state {
            case .idle:
                Text("Ready")
                    .font(.headline)
            
            case .discovering:
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Discovering devices...")
                        .font(.headline)
                }
            
            case .connecting:
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Connecting...")
                        .font(.headline)
                    if !service.currentItem.isEmpty {
                        Text(service.currentItem)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            
            case .transferring(let progress, let bytesTransferred, let totalBytes, let speed):
                VStack(spacing: 16) {
                    // Progress Circle
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                LinearGradient(colors: [.blue, .green], startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear, value: progress)
                        
                        VStack(spacing: 4) {
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                            Text(formatBytes(bytesTransferred))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Transfer Details
                    VStack(spacing: 8) {
                        HStack {
                            Text("Progress:")
                            Spacer()
                            Text("\(formatBytes(bytesTransferred)) / \(formatBytes(totalBytes))")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Text("Speed:")
                            Spacer()
                            Text("\(formatSpeed(speed))")
                                .foregroundStyle(.secondary)
                        }
                        
                        if !service.currentItem.isEmpty {
                            HStack {
                                Text("Current:")
                                Spacer()
                                Text(service.currentItem)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        if totalBytes > 0 && speed > 0 {
                            let remaining = Double(totalBytes - bytesTransferred) / speed
                            HStack {
                                Text("Remaining:")
                                Spacer()
                                Text(formatTime(remaining))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .font(.subheadline)
                    .padding(.horizontal)
                }
            
            case .completed:
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                    Text("Transfer Complete")
                        .font(.headline)
                    if !service.currentItem.isEmpty {
                        Text(service.currentItem)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            
            case .failed(let error):
                VStack(spacing: 12) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.red)
                    Text("Transfer Failed")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            // Action Buttons
            HStack(spacing: 16) {
                if case .transferring = service.state {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .foregroundStyle(.red)
                            .cornerRadius(12)
                    }
                } else if service.canRetry {
                    Button(action: onRetry) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Retry")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .foregroundStyle(.blue)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(24)
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch service.state {
        case .idle:
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 50))
                .foregroundStyle(.blue)
        case .discovering, .connecting:
            if #available(iOS 17.0, *) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse, options: .repeating)
            } else {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)
            }
        case .transferring:
            EmptyView()
        case .completed:
            EmptyView()
        case .failed:
            EmptyView()
        }
    }
    
    // MARK: - Helpers
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytesPerSecond)) + "/s"
    }
    
    private func formatTime(_ seconds: Double) -> String {
        if seconds < 60 {
            return String(format: "%.0fs", seconds)
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
            return "\(minutes)m \(secs)s"
        } else {
            let hours = Int(seconds / 3600)
            let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(minutes)m"
        }
    }
}
