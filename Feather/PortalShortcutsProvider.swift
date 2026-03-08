import AppIntents

// MARK: - Portal Shortcuts Provider

/// Registers curated Portal App Shortcuts that appear automatically in Siri and the Shortcuts app.
/// Users can also discover and add any Portal AppIntent manually from the Shortcuts app.
struct PortalShortcutsProvider: AppShortcutsProvider {

    // MARK: - App Shortcuts

    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {

        // MARK: Apps Category
        AppShortcut(
            intent: InstallPortalAppIntent(),
            phrases: [
                "Install an app with \(.applicationName)",
                "Install app using \(.applicationName)"
            ],
            shortTitle: "Install App",
            systemImageName: "square.and.arrow.down"
        )

        AppShortcut(
            intent: UpdateAllPortalAppsIntent(),
            phrases: [
                "Update all apps in \(.applicationName)",
                "Update \(.applicationName) apps"
            ],
            shortTitle: "Update All Apps",
            systemImageName: "arrow.triangle.2.circlepath.circle"
        )

        AppShortcut(
            intent: CheckPortalUpdatesIntent(),
            phrases: [
                "Check for updates in \(.applicationName)",
                "Check \(.applicationName) updates"
            ],
            shortTitle: "Check Updates",
            systemImageName: "magnifyingglass.circle"
        )

        // MARK: Sources Category
        AppShortcut(
            intent: RefreshPortalSourcesIntent(),
            phrases: [
                "Refresh \(.applicationName) sources",
                "Refresh all sources in \(.applicationName)"
            ],
            shortTitle: "Refresh Sources",
            systemImageName: "arrow.clockwise.circle"
        )

        AppShortcut(
            intent: AddPortalSourceIntent(),
            phrases: [
                "Add a source to \(.applicationName)",
                "Add source in \(.applicationName)"
            ],
            shortTitle: "Add Source",
            systemImageName: "plus.circle"
        )

        // MARK: Library Category
        AppShortcut(
            intent: GetInstalledPortalAppsIntent(),
            phrases: [
                "List installed apps in \(.applicationName)",
                "Show \(.applicationName) library"
            ],
            shortTitle: "Installed Apps",
            systemImageName: "square.stack"
        )

        AppShortcut(
            intent: SearchPortalAppsIntent(),
            phrases: [
                "Search for apps in \(.applicationName)",
                "Search \(.applicationName)"
            ],
            shortTitle: "Search Apps",
            systemImageName: "magnifyingglass"
        )

        // MARK: Navigation Category
        AppShortcut(
            intent: OpenPortalHomeIntent(),
            phrases: [
                "Open \(.applicationName) home",
                "Go to \(.applicationName) home"
            ],
            shortTitle: "Open Home",
            systemImageName: "house"
        )

        // MARK: Maintenance Category
        AppShortcut(
            intent: PortalDiagnosticsIntent(),
            phrases: [
                "Run \(.applicationName) diagnostics",
                "Show \(.applicationName) diagnostics"
            ],
            shortTitle: "Diagnostics",
            systemImageName: "stethoscope"
        )

        AppShortcut(
            intent: ClearPortalCacheIntent(),
            phrases: [
                "Clear \(.applicationName) cache",
                "Clear cache in \(.applicationName)"
            ],
            shortTitle: "Clear Cache",
            systemImageName: "trash.circle"
        )
    }
}

// MARK: - Intent Category Metadata

/// Describes the categories available for Portal App Intents in the Shortcuts app.
/// This provides documentation for grouping intents when users browse Portal actions.
enum PortalIntentCategory: String, CaseIterable {
    case apps = "Apps"
    case sources = "Sources"
    case library = "Library"
    case downloads = "Downloads"
    case navigation = "Navigation"
    case maintenance = "Maintenance"
    case advanced = "Advanced"

    var icon: String {
        switch self {
        case .apps: return "square.and.arrow.down"
        case .sources: return "externaldrive.connected.to.line.below"
        case .library: return "square.stack"
        case .downloads: return "arrow.down.circle"
        case .navigation: return "arrow.right.circle"
        case .maintenance: return "wrench.and.screwdriver"
        case .advanced: return "gearshape.2"
        }
    }

    var intents: [String] {
        switch self {
        case .apps:
            return [
                "Install Portal App",
                "Download Portal App",
                "Open Portal App",
                "Uninstall Portal App",
                "Reinstall Portal App",
                "Update Portal App",
                "Update All Portal Apps",
                "Check Portal Updates"
            ]
        case .sources:
            return [
                "Add Portal Source",
                "Remove Portal Source",
                "Refresh Portal Sources",
                "Refresh Portal Source",
                "Import Portal Repository",
                "Export Portal Sources"
            ]
        case .library:
            return [
                "Get Installed Portal Apps",
                "Get Portal Available Updates",
                "Search Portal Apps",
                "Open Portal App Page"
            ]
        case .downloads:
            return [
                "Pause Portal Download",
                "Resume Portal Download",
                "Cancel Portal Download",
                "Get Active Portal Downloads"
            ]
        case .navigation:
            return [
                "Open Portal Home",
                "Open Portal Apps",
                "Open Portal Installed Apps",
                "Open Portal Updates",
                "Open Portal Sources",
                "Open Portal Settings"
            ]
        case .maintenance:
            return [
                "Refresh Portal",
                "Clear Portal Cache",
                "Reset Portal Sources",
                "Portal Diagnostics",
                "Reload Portal UI"
            ]
        case .advanced:
            return [
                "Install Portal App from URL",
                "Bulk Install Portal Apps",
                "Share Portal App"
            ]
        }
    }
}
