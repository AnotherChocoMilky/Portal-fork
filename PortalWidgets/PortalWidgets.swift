import WidgetKit
import SwiftUI

@main
struct PortalWidgetsBundle: WidgetBundle {
    var body: some Widget {
        QuickActionsWidget()
        CertificateStatusWidget()
    }
}

// MARK: - Timeline Entry
struct WidgetEntry: TimelineEntry {
    let date: Date
    let certName: String
    let expiryDate: Date?
    let daysRemaining: Int?
    
    static var placeholder: WidgetEntry {
        WidgetEntry(date: Date(), certName: "Certificate", expiryDate: Date().addingTimeInterval(86400 * 30), daysRemaining: 30)
    }
    
    static var empty: WidgetEntry {
        WidgetEntry(date: Date(), certName: "No Certificate", expiryDate: nil, daysRemaining: nil)
    }
}

// MARK: - Timeline Provider
struct WidgetTimelineProvider: TimelineProvider {
    private let appGroupID = "group.ayon1xw.Portal"
    
    func placeholder(in context: Context) -> WidgetEntry {
        .placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
        } else {
            completion(getCurrentEntry())
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let entry = getCurrentEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func getCurrentEntry() -> WidgetEntry {
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            return .empty
        }
        
        let certName = userDefaults.string(forKey: "widget.selectedCertName") ?? "No Certificate"
        let expiryTime = userDefaults.double(forKey: "widget.selectedCertExpiry")
        
        var expiryDate: Date? = nil
        var daysRemaining: Int? = nil
        
        if expiryTime > 0 {
            expiryDate = Date(timeIntervalSince1970: expiryTime)
            daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate!).day
        }
        
        return WidgetEntry(date: Date(), certName: certName, expiryDate: expiryDate, daysRemaining: daysRemaining)
    }
}

// MARK: - Quick Actions Widget
struct QuickActionsWidget: Widget {
    let kind: String = "QuickActionsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetTimelineProvider()) { entry in
            QuickActionsWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Actions")
        .description("Quickly add sources or certificates to Portal.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

struct QuickActionsWidgetView: View {
    var entry: WidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallWidget
            case .systemMedium:
                mediumWidget
            case .accessoryCircular:
                accessoryCircularWidget
            case .accessoryRectangular:
                accessoryRectangularWidget
            default:
                Text("Portal")
            }
        }
        .widgetBackground()
    }
    
    private var smallWidget: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "app.badge.fill")
                    .font(.title3)
                    .foregroundStyle(.accent)
                Spacer()
            }
            
            Spacer()
            
            Link(destination: URL(string: "portal://add-source")!) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Add Source")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            
            Link(destination: URL(string: "portal://add-certificate")!) {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text("Add Cert")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(14)
    }
    
    private var mediumWidget: some View {
        HStack(spacing: 12) {
            Link(destination: URL(string: "portal://add-source")!) {
                VStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.blue)
                    Text("Add Source")
                        .font(.system(size: 12, weight: .semibold))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            
            Link(destination: URL(string: "portal://add-certificate")!) {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.green)
                    Text("Add Cert")
                        .font(.system(size: 12, weight: .semibold))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            
            Link(destination: URL(string: "portal://open-certificates")!) {
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 28))
                        .foregroundStyle(.orange)
                    Text("Check Expiry")
                        .font(.system(size: 12, weight: .semibold))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(14)
    }
    
    private var accessoryCircularWidget: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "plus.circle.fill")
                .font(.title2)
        }
        .widgetURL(URL(string: "portal://add-source"))
    }
    
    private var accessoryRectangularWidget: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                Text("Portal")
                    .font(.headline)
            }
            Text("Quick Actions")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .widgetURL(URL(string: "portal://add-certificate"))
    }
}

// MARK: - Certificate Status Widget
struct CertificateStatusWidget: Widget {
    let kind: String = "CertificateStatusWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetTimelineProvider()) { entry in
            CertificateStatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Certificate Status")
        .description("Monitor your certificate's expiration status.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

struct CertificateStatusWidgetView: View {
    var entry: WidgetEntry
    @Environment(\.widgetFamily) var family
    
    private var statusColor: Color {
        guard let days = entry.daysRemaining else { return .secondary }
        if days < 0 { return .red }
        if days < 7 { return .orange }
        if days < 30 { return .yellow }
        return .green
    }
    
    private var statusText: String {
        guard let days = entry.daysRemaining else { return "No data" }
        if days < 0 { return "Expired" }
        if days == 0 { return "Expires today" }
        if days == 1 { return "1 day left" }
        return "\(days) days left"
    }
    
    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallWidget
            case .accessoryRectangular:
                accessoryRectangularWidget
            default:
                smallWidget
            }
        }
        .widgetBackground()
        .widgetURL(URL(string: "portal://open-certificates"))
    }
    
    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(statusColor)
                Text("Certificate")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(entry.certName)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(statusColor)
            }
        }
        .padding(14)
    }
    
    private var accessoryRectangularWidget: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.certName)
                .font(.headline)
                .lineLimit(1)
            
            Text(statusText)
                .font(.body)
                .foregroundStyle(entry.daysRemaining ?? 0 < 7 ? .red : .primary)
        }
    }
}

// MARK: - Widget Background Extension
extension View {
    func widgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            return self.containerBackground(.fill.tertiary, for: .widget)
        } else {
            return self.padding().background(Color(.systemBackground))
        }
    }
}
