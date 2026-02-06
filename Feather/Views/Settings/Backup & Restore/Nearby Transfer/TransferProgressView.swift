import SwiftUI

// MARK: - Transfer Progress View
struct TransferProgressView: View {
    @ObservedObject var service: NearbyTransferService
    let onCancel: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Status Icon
                statusIcon
                
                // Progress Information
                switch service.state {
                case .idle:
                    modernStatusCard(
                        icon: "antenna.radiowaves.left.and.right",
                        title: "Ready!",
                        subtitle: "Waiting To Begin Transfer",
                        color: .blue
                    )
                
                case .discovering:
                    modernStatusCard(
                        icon: "magnifyingglass",
                        title: "Discovering Devices",
                        subtitle: "Searching For Nearby Devices",
                        color: .purple,
                        showProgress: true
                    )
                
                case .connecting:
                    modernStatusCard(
                        icon: "wifi",
                        title: "Connecting",
                        subtitle: service.currentItem.isEmpty ? "Establishing Connection" : service.currentItem,
                        color: .orange,
                        showProgress: true
                    )
                
                case .transferring(let progress, let bytesTransferred, let totalBytes, let speed):
                    modernTransferView(
                        progress: progress,
                        bytesTransferred: bytesTransferred,
                        totalBytes: totalBytes,
                        speed: speed
                    )
                
                case .completed:
                    modernStatusCard(
                        icon: "checkmark.circle.fill",
                        title: "Transfer Complete",
                        subtitle: service.currentItem.isEmpty ? "All Files Transferred Successfully" : service.currentItem,
                        color: .green
                    )
                
                case .failed(let error):
                    modernStatusCard(
                        icon: "xmark.circle.fill",
                        title: "Transfer Failed",
                        subtitle: error.localizedDescription,
                        color: .red
                    )
                }
                
                // Action Buttons
                actionButtons
            }
            .padding(24)
        }
    }
    
    // MARK: - Modern Transfer View
    @ViewBuilder
    private func modernTransferView(progress: Double, bytesTransferred: Int64, totalBytes: Int64, speed: Double) -> some View {
        VStack(spacing: 24) {
            // Large Progress Circle with Gradient
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 12)
                    .frame(width: 180, height: 180)
                
                // Progress circle with gradient
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [.blue, .purple, .pink, .blue],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.3), value: progress)
                
                // Center content
                VStack(spacing: 6) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text(formatBytes(bytesTransferred))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 12)
            
            // Modern Info Cards
            VStack(spacing: 12) {
                infoCard(
                    icon: "arrow.up.arrow.down",
                    label: "Progress",
                    value: "\(formatBytes(bytesTransferred)) / \(formatBytes(totalBytes))",
                    color: .blue
                )
                
                infoCard(
                    icon: "speedometer",
                    label: "Speed",
                    value: formatSpeed(speed),
                    color: .green
                )
                
                if !service.currentItem.isEmpty {
                    infoCard(
                        icon: "doc.fill",
                        label: "Current File",
                        value: service.currentItem,
                        color: .purple
                    )
                }
                
                if totalBytes > 0 && speed > 0 {
                    let remaining = Double(totalBytes - bytesTransferred) / speed
                    infoCard(
                        icon: "clock.fill",
                        label: "Time Remaining",
                        value: formatTime(remaining),
                        color: .orange
                    )
                }
            }
        }
    }
    
    // MARK: - Modern Status Card
    @ViewBuilder
    private func modernStatusCard(icon: String, title: String, subtitle: String, color: Color, showProgress: Bool = false) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 44))
                    .foregroundStyle(color)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            if showProgress {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Info Card
    @ViewBuilder
    private func infoCard(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground))
        )
    }
    
    // MARK: - Action Buttons
    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 12) {
            if case .transferring = service.state {
                Button(action: onCancel) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark")
                        Text("Cancel Transfer")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.red.opacity(0.15), Color.red.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            } else if service.canRetry {
                Button(action: onRetry) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.15), Color.blue.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch service.state {
        case .idle:
            EmptyView()
        case .discovering, .connecting:
            EmptyView()
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
