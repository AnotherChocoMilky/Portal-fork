import SwiftUI
import ActivityKit
import WidgetKit

/// Live Activity view for app installation progress
@available(iOS 16.1, *)
struct InstallationLiveActivityView: View {
    let context: ActivityViewContext<InstallationActivityAttributes>
    @AppStorage("liveActivityStyle") private var style: LiveActivityStyle = .modern
    @AppStorage("liveActivityShowTimeRemaining") private var showTimeRemaining: Bool = true
    @AppStorage("liveActivityShowIcon") private var showIcon: Bool = true
    
    var body: some View {
        Group {
            switch style {
            case .modern:
                modernStyle
            case .compact:
                compactStyle
            case .minimal:
                minimalStyle
            }
        }
    }
    
    // MARK: - Modern Style
    private var modernStyle: some View {
        HStack(spacing: 12) {
            // App Icon
            if showIcon {
                appIconView
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // App Name
                Text(context.attributes.appName)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                
                // Status
                HStack(spacing: 4) {
                    Image(systemName: context.state.status.icon)
                        .font(.system(size: 10))
                        .foregroundColor(context.state.status.color)
                    
                    Text(context.state.status.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Progress Bar
                progressBar
                
                // Details
                HStack {
                    Text("\(context.state.formattedBytesDownloaded) Of \(context.state.formattedTotalBytes)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if showTimeRemaining, let timeStr = context.state.formattedTimeRemaining {
                        Text(timeStr)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Percentage
            Text(context.state.progressPercentage)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(context.state.status.color)
        }
        .padding(12)
    }
    
    // MARK: - Compact Style
    private var compactStyle: some View {
        HStack(spacing: 10) {
            if showIcon {
                appIconView
                    .frame(width: 32, height: 32)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.appName)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                
                progressBar
                
                HStack {
                    Text(context.state.status.rawValue)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(context.state.progressPercentage)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(context.state.status.color)
                }
            }
        }
        .padding(10)
    }
    
    // MARK: - Minimal Style
    private var minimalStyle: some View {
        VStack(spacing: 8) {
            HStack {
                Text(context.attributes.appName)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                
                Spacer()
                
                Text(context.state.progressPercentage)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(context.state.status.color)
            }
            
            progressBar
        }
        .padding(8)
    }
    
    // MARK: - Components
    
    private var appIconView: some View {
        Group {
            if let iconData = context.attributes.appIcon,
               let uiImage = UIImage(data: iconData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Image(systemName: "app.badge.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [context.state.status.color.opacity(0.8), context.state.status.color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(context.state.progress))
                    .animation(.easeInOut(duration: 0.3), value: context.state.progress)
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Live Activity Style Enum

enum LiveActivityStyle: String, CaseIterable, Codable {
    case modern = "Modern"
    case compact = "Compact"
    case minimal = "Minimal"
    
    var description: String {
        switch self {
        case .modern: return "Full details with icon and progress"
        case .compact: return "Condensed view with essential info"
        case .minimal: return "Minimal progress bar only"
        }
    }
    
    var icon: String {
        switch self {
        case .modern: return "rectangle.fill"
        case .compact: return "rectangle.compress.vertical"
        case .minimal: return "minus"
        }
    }
}
