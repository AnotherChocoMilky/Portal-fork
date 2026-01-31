import WidgetKit
import SwiftUI
import AppIntents

@main
@available(iOS 17.0, *)
struct PortalWidgetsBundle: WidgetBundle {
    var body: some Widget {
        QuickActionsWidget()
        CertificateStatusWidget()
        AllInOneWidget()
    }
}

// MARK: - App Intents
struct AddSourceIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Source"
    static var description = IntentDescription("Open Portal to add a new source.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct AddCertificateIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Certificate"
    static var description = IntentDescription("Open Portal to add a new certificate.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct OpenCertificatesIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Certificates"
    static var description = IntentDescription("Open Portal to view certificates.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct SignAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Sign App"
    static var description = IntentDescription("Open Portal to sign an app.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct AddAndSignIntent: AppIntent {
    static var title: LocalizedStringResource = "Add and Sign IPA"
    static var description = IntentDescription("Open Portal to add and sign an IPA.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct ClearCachesIntent: AppIntent {
    static var title: LocalizedStringResource = "Clear Caches"
    static var description = IntentDescription("Clear Portal's work cache.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct ExportLogsIntent: AppIntent {
    static var title: LocalizedStringResource = "Export Logs"
    static var description = IntentDescription("Export Portal's diagnostic logs.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct RebuildIconCacheIntent: AppIntent {
    static var title: LocalizedStringResource = "Rebuild Icon Cache"
    static var description = IntentDescription("Rebuild broken app icons.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct OpenSettingsIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Settings"
    static var description = IntentDescription("Open Portal's settings.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct OpenAboutIntent: AppIntent {
    static var title: LocalizedStringResource = "Open About"
    static var description = IntentDescription("Open Portal's about page.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct QuickActionsIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Actions"
    static var description = IntentDescription("Open Portal's quick actions menu.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

@available(iOS 17.0, *)
struct PortalConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Portal"
    static var description = IntentDescription("Customize your Portal widget.")

    @Parameter(title: "Custom Title", default: "Portal")
    var customTitle: String?

    @Parameter(title: "Show Expiry Date", default: true)
    var showExpiry: Bool
}

// MARK: - Timeline Entry
@available(iOS 17.0, *)
struct WidgetEntry: TimelineEntry {
    let date: Date
    let certName: String
    let expiryDate: Date?
    let daysRemaining: Int?
    let configuration: PortalConfigurationIntent
    
    static var placeholder: WidgetEntry {
        WidgetEntry(date: Date(), certName: "Certificate", expiryDate: Date().addingTimeInterval(86400 * 30), daysRemaining: 30, configuration: PortalConfigurationIntent())
    }
    
    static var empty: WidgetEntry {
        WidgetEntry(date: Date(), certName: "No Certificate", expiryDate: nil, daysRemaining: nil, configuration: PortalConfigurationIntent())
    }
}

// MARK: - Timeline Provider
@available(iOS 17.0, *)
struct WidgetTimelineProvider: AppIntentTimelineProvider {
    private let appGroupID = "group.ayon1xw.Portal"
    
    func placeholder(in context: Context) -> WidgetEntry {
        .placeholder
    }
    
    func snapshot(for configuration: PortalConfigurationIntent, in context: Context) async -> WidgetEntry {
        if context.isPreview {
            return .placeholder
        } else {
            return getCurrentEntry(for: configuration)
        }
    }
    
    func timeline(for configuration: PortalConfigurationIntent, in context: Context) async -> Timeline<WidgetEntry> {
        let entry = getCurrentEntry(for: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        return timeline
    }
    
    private func getCurrentEntry(for configuration: PortalConfigurationIntent) -> WidgetEntry {
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            return .empty
        }
        
        let certName = configuration.customTitle ?? userDefaults.string(forKey: "widget.selectedCertName") ?? "No Certificate"
        let expiryTime = userDefaults.double(forKey: "widget.selectedCertExpiry")
        
        var expiryDate: Date? = nil
        var daysRemaining: Int? = nil
        
        if expiryTime > 0 {
            expiryDate = Date(timeIntervalSince1970: expiryTime)
            daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate!).day
        }
        
        return WidgetEntry(date: Date(), certName: certName, expiryDate: expiryDate, daysRemaining: daysRemaining, configuration: configuration)
    }
}

// MARK: - Quick Actions Widget
@available(iOS 17.0, *)
struct QuickActionsWidget: Widget {
    let kind: String = "QuickActionsWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: PortalConfigurationIntent.self, provider: WidgetTimelineProvider()) { entry in
            QuickActionsWidgetThumbnailView(entry: entry)
        }
        .configurationDisplayName("Quick Actions")
        .description("Quickly add sources or certificates to Portal.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

@available(iOS 17.0, *)
struct QuickActionsWidgetThumbnailView: View {
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
                    .foregroundStyle(Color.accentColor)
                if let title = entry.configuration.customTitle, !title.isEmpty {
                    Text(title)
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                }
                Spacer()
            }
            
            Spacer()
            
            ActionRow(intent: AddSourceIntent(), icon: "plus.circle.fill", label: "Add Source", color: .blue, url: "portal://add-source")
            ActionRow(intent: AddCertificateIntent(), icon: "checkmark.seal.fill", label: "Add Cert", color: .green, url: "portal://add-certificate")
        }
        .padding(14)
    }
    
    private var mediumWidget: some View {
        HStack(spacing: 12) {
            ActionCard(intent: AddSourceIntent(), icon: "plus.circle.fill", label: "Add Source", color: .blue, url: "portal://add-source")
            ActionCard(intent: AddCertificateIntent(), icon: "checkmark.seal.fill", label: "Add Cert", color: .green, url: "portal://add-certificate")
            ActionCard(intent: OpenCertificatesIntent(), icon: "calendar.badge.clock", label: "Check Expiry", color: .orange, url: "portal://open-certificates")
        }
        .padding(14)
    }
    
    private var accessoryCircularWidget: some View {
        ActionButton(intent: QuickActionsIntent(), url: "portal://quick-actions") {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
    
    private var accessoryRectangularWidget: some View {
        ActionButton(intent: QuickActionsIntent(), url: "portal://quick-actions") {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(Color.accentColor)
                    Text(entry.configuration.customTitle ?? "Portal")
                        .font(.headline)
                        .lineLimit(1)
                }
                Text("Quick Actions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - All In One Widget
@available(iOS 17.0, *)
struct AllInOneWidget: Widget {
    let kind: String = "AllInOneWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: PortalConfigurationIntent.self, provider: WidgetTimelineProvider()) { entry in
            AllInOneWidgetView(entry: entry)
        }
        .configurationDisplayName("All In One")
        .description("Quick access to all Portal tools.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

@available(iOS 17.0, *)
struct AllInOneWidgetView: View {
    var entry: WidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "square.grid.2x2.fill")
                        .foregroundStyle(Color.accentColor)
                    Text(entry.configuration.customTitle ?? "Portal")
                        .font(.system(size: 16, weight: .bold))
                }
                Spacer()
                Text("All-In-One")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Capsule())
            }

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    QuickToolButton(intent: SignAppIntent(), icon: "signature", title: "Sign", color: .blue, url: "portal://sign-app")
                    QuickToolButton(intent: AddAndSignIntent(), icon: "plus.app.fill", title: "Add & Sign", color: .green, url: "portal://add-and-sign")
                    QuickToolButton(intent: AddSourceIntent(), icon: "plus.circle.fill", title: "Source", color: .orange, url: "portal://add-source")
                }

                HStack(spacing: 8) {
                    QuickToolButton(intent: AddCertificateIntent(), icon: "checkmark.seal.fill", title: "Add Cert", color: .purple, url: "portal://add-certificate")
                    QuickToolButton(intent: ClearCachesIntent(), icon: "trash.fill", title: "Clear", color: .red, url: "portal://clear-caches")
                    QuickToolButton(intent: ExportLogsIntent(), icon: "doc.text.fill", title: "Logs", color: .gray, url: "portal://export-logs")
                }

                if family == .systemLarge {
                    HStack(spacing: 8) {
                        QuickToolButton(intent: RebuildIconCacheIntent(), icon: "app.badge.fill", title: "Icons", color: .cyan, url: "portal://rebuild-icon-cache")
                        QuickToolButton(intent: OpenSettingsIntent(), icon: "gearshape.fill", title: "Settings", color: .indigo, url: "portal://open-settings")
                        QuickToolButton(intent: OpenAboutIntent(), icon: "info.circle.fill", title: "About", color: .teal, url: "portal://open-about")
                    }

                    Spacer(minLength: 0)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.certName)
                                .font(.system(size: 12, weight: .bold))
                            if entry.configuration.showExpiry, let days = entry.daysRemaining {
                                Text("\(days) days remaining")
                                    .font(.system(size: 10))
                                    .foregroundStyle(days < 7 ? .red : .secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(entry.daysRemaining ?? 0 < 7 ? .orange : .green)
                    }
                    .padding(10)
                    .background(Color.accentColor.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(14)
        .widgetBackground()
    }
}

@available(iOS 17.0, *)
struct QuickToolButton<I: AppIntent>: View {
    let intent: I
    let icon: String
    let title: String
    let color: Color
    let url: String

    var body: some View {
        ActionButton(intent: intent, url: url) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

// MARK: - Certificate Status Widget
@available(iOS 17.0, *)
struct CertificateStatusWidget: Widget {
    let kind: String = "CertificateStatusWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: PortalConfigurationIntent.self, provider: WidgetTimelineProvider()) { entry in
            CertificateStatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Certificate Status")
        .description("Monitor your certificate's expiration status.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

@available(iOS 17.0, *)
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
        ActionButton(intent: OpenCertificatesIntent(), url: "portal://open-certificates") {
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
        }
        .widgetBackground()
    }
    
    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(statusColor)
                Text(entry.configuration.customTitle ?? "Certificate")
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
            
            if entry.configuration.showExpiry {
                Text(statusText)
                    .font(.body)
                    .foregroundStyle(entry.daysRemaining ?? 0 < 7 ? .red : .primary)
            }
        }
    }
}

// MARK: - Interactive Components
@available(iOS 17.0, *)
struct ActionButton<I: AppIntent, Content: View>: View {
    let intent: I
    let url: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        if #available(iOS 17.0, *) {
            Button(intent: intent) {
                content()
            }
            .buttonStyle(.plain)
        } else {
            Link(destination: URL(string: url)!) {
                content()
            }
        }
    }
}

@available(iOS 17.0, *)
struct ActionRow<I: AppIntent>: View {
    let intent: I
    let icon: String
    let label: String
    let color: Color
    let url: String

    var body: some View {
        ActionButton(intent: intent, url: url) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

@available(iOS 17.0, *)
struct ActionCard<I: AppIntent>: View {
    let intent: I
    let icon: String
    let label: String
    let color: Color
    let url: String

    var body: some View {
        ActionButton(intent: intent, url: url) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
