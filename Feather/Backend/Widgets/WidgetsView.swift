import WidgetKit
import SwiftUI
import AppIntents

// MARK: - DEPRECATED
// ⚠️ This file is DEPRECATED and kept only for reference.
// 
// The actual widget implementation is now in the PortalWidgets extension target.
// See: /PortalWidgets/PortalWidgets.swift
//
// To enable widgets on the home screen, you MUST:
// 1. Add a Widget Extension target to the Xcode project
// 2. Use the files in the /PortalWidgets directory
// 3. Configure App Groups on both the main app and widget extension
// 4. See /PortalWidgets/README.md for complete setup instructions

// MARK: - App Intents
@available(iOS 16.0, *)
struct AddSourceIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Source"
    static var description = IntentDescription("Open Portal to add a new source.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

@available(iOS 16.0, *)
struct AddCertificateIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Certificate"
    static var description = IntentDescription("Open Portal to add a new certificate.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

@available(iOS 16.0, *)
struct CheckExpiryIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Expiry"
    static var description = IntentDescription("Check the expiration of your certificates.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), certName: "No Certificate", expiryDate: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), certName: "Example Certificate", expiryDate: Date().addingTimeInterval(86400 * 30))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.ayon1xw.Portal") ?? .standard

        let certName = userDefaults.string(forKey: "widget.selectedCertName") ?? "No Certificate"
        let expiryTime = userDefaults.double(forKey: "widget.selectedCertExpiry")
        let expiryDate = expiryTime > 0 ? Date(timeIntervalSince1970: expiryTime) : nil

        let entry = SimpleEntry(date: Date(), certName: certName, expiryDate: expiryDate)

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let certName: String
    let expiryDate: Date?
}

// MARK: - Widget Views
struct QuickActionsWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if #available(iOS 17.0, *) {
            content
                .containerBackground(.fill.tertiary, for: .widget)
        } else {
            content
                .padding()
                .background(Color(.systemBackground))
        }
    }

    @ViewBuilder
    var content: some View {
        switch family {
        case .systemSmall:
            VStack(spacing: 12) {
                Link(destination: URL(string: "portal://add-source")!) {
                    actionRow(icon: "plus.circle.fill", label: "Source", color: .blue)
                }
                Link(destination: URL(string: "portal://add-certificate")!) {
                    actionRow(icon: "checkmark.seal.fill", label: "Cert", color: .green)
                }
            }
            .padding(12)

        case .systemMedium:
            HStack(spacing: 12) {
                Link(destination: URL(string: "portal://add-source")!) {
                    actionCard(icon: "plus.circle.fill", label: "Add Source", color: .blue)
                }
                Link(destination: URL(string: "portal://add-certificate")!) {
                    actionCard(icon: "checkmark.seal.fill", label: "Add Cert", color: .green)
                }
                Link(destination: URL(string: "portal://open-certificates")!) {
                    actionCard(icon: "calendar.badge.clock", label: "Expiry", color: .orange)
                }
            }
            .padding(12)

        case .accessoryCircular:
            VStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
            .widgetURL(URL(string: "portal://add-source"))

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text("Add Cert")
                        .font(.headline)
                }
                Text("Quick Import")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .widgetURL(URL(string: "portal://add-certificate"))

        default:
            Text("Select Widget")
        }
    }

    func actionRow(icon: String, label: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 14, weight: .semibold))
            Spacer()
        }
        .padding(8)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(8)
    }

    func actionCard(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CertificateStatusWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            if family == .accessoryRectangular {
                accessoryRectangularContent
            } else {
                standardContent
            }
        }
        .widgetBackground()
        .widgetURL(URL(string: "portal://open-certificates"))
    }

    var standardContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Text("Cert Status")
                    .font(.system(size: 12, weight: .bold))
            }

            Spacer()

            Text(entry.certName)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(2)

            if let expiry = entry.expiryDate {
                let days = Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
                Text(days < 0 ? "Expired" : "Expires in \(days)d")
                    .font(.system(size: 11))
                    .foregroundStyle(days < 7 ? .red : .secondary)
            } else {
                Text("No data")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
    }

    var accessoryRectangularContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(entry.certName)
                .font(.headline)
                .lineLimit(1)

            if let expiry = entry.expiryDate {
                let days = Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
                Text(days < 0 ? "Expired" : "\(days) days left")
                    .font(.body)
                    .foregroundStyle(days < 7 ? .red : .primary)
            } else {
                Text("Tap to check")
                    .font(.body)
            }
        }
    }
}

extension View {
    func widgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            return self.containerBackground(.fill.tertiary, for: .widget)
        } else {
            return self.padding().background(Color(.systemBackground))
        }
    }
}

// MARK: - Widgets
struct QuickActionsWidget: Widget {
    let kind: String = "QuickActionsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QuickActionsWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Actions")
        .description("Quickly add sources or certificates to Portal.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

struct CertificateStatusWidget: Widget {
    let kind: String = "CertificateStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CertificateStatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Certificate Status")
        .description("Monitor your certificate's expiration status.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

// @main // Commented out to avoid multiple entry points in the main project
struct PortalWidgetsBundle: WidgetBundle {
    var body: some Widget {
        QuickActionsWidget()
        CertificateStatusWidget()
    }
}
