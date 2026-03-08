import AppIntents
import Foundation

// Delay (in nanoseconds) applied before navigation intents post tab-switch notifications.
// This ensures the SwiftUI view hierarchy has registered its observers when Portal
// launches from a terminated state before the notification is dispatched.
private let coldLaunchNavigationDelay: UInt64 = 300_000_000

// MARK: - App Management Intents

struct InstallPortalAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Install Portal App"
    static var description = IntentDescription("Installs an app from Portal sources using its app ID")
    static var openAppWhenRun = true

    @Parameter(title: "App ID", description: "The bundle identifier or app ID to install")
    var appID: String

    @Parameter(title: "Source", description: "Optional source URL to install from")
    var source: String?

    @Parameter(title: "Auto Open", description: "Automatically open the app after installation", default: false)
    var autoOpen: Bool

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmed = appID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw $appID.needsValueError("Please provide an App ID")
        }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        var urlString = "portal://install?id=\(encoded)"
        if let source, let encodedSource = source.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            urlString += "&source=\(encodedSource)"
        }
        await MainActor.run {
            if let url = URL(string: urlString) {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        if autoOpen {
            try await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                if let openURL = URL(string: "portal://openapp?id=\(encoded)") {
                    URLSchemeHandlerManager.shared.handleURL(openURL)
                }
            }
        }
        return .result(value: "Installing \(trimmed)")
    }
}

struct DownloadPortalAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Download Portal App"
    static var description = IntentDescription("Downloads an app from Portal sources without installing it")
    static var openAppWhenRun = true

    @Parameter(title: "App ID", description: "The bundle identifier or app ID to download")
    var appID: String

    @Parameter(title: "Source", description: "Optional source URL to download from")
    var source: String?

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmed = appID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw $appID.needsValueError("Please provide an App ID")
        }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        var urlString = "portal://download?id=\(encoded)"
        if let source, let encodedSource = source.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            urlString += "&source=\(encodedSource)"
        }
        await MainActor.run {
            if let url = URL(string: urlString) {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result(value: "Downloading \(trimmed)")
    }
}

struct OpenPortalAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Portal App"
    static var description = IntentDescription("Opens an installed app through Portal")
    static var openAppWhenRun = true

    @Parameter(title: "App ID", description: "The bundle identifier or app ID to open")
    var appID: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmed = appID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw $appID.needsValueError("Please provide an App ID")
        }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        await MainActor.run {
            if let url = URL(string: "portal://openapp?id=\(encoded)") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result(value: "Opening \(trimmed)")
    }
}

struct UninstallPortalAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Uninstall Portal App"
    static var description = IntentDescription("Uninstalls an app from Portal")
    static var openAppWhenRun = true

    @Parameter(title: "App ID", description: "The bundle identifier or app ID to uninstall")
    var appID: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmed = appID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw $appID.needsValueError("Please provide an App ID")
        }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        await MainActor.run {
            if let url = URL(string: "portal://uninstall?id=\(encoded)") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result(value: "Uninstalling \(trimmed)")
    }
}

struct ReinstallPortalAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Reinstall Portal App"
    static var description = IntentDescription("Reinstalls an app through Portal")
    static var openAppWhenRun = true

    @Parameter(title: "App ID", description: "The bundle identifier or app ID to reinstall")
    var appID: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmed = appID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw $appID.needsValueError("Please provide an App ID")
        }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        await MainActor.run {
            if let url = URL(string: "portal://reinstall?id=\(encoded)") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result(value: "Reinstalling \(trimmed)")
    }
}

struct UpdatePortalAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Update Portal App"
    static var description = IntentDescription("Updates an app to its latest version through Portal")
    static var openAppWhenRun = true

    @Parameter(title: "App ID", description: "The bundle identifier or app ID to update")
    var appID: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmed = appID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw $appID.needsValueError("Please provide an App ID")
        }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        await MainActor.run {
            if let url = URL(string: "portal://updateapp?id=\(encoded)") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result(value: "Updating \(trimmed)")
    }
}

struct UpdateAllPortalAppsIntent: AppIntent {
    static var title: LocalizedStringResource = "Update All Portal Apps"
    static var description = IntentDescription("Updates all apps with available updates through Portal")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let updates = await MainActor.run {
            AppUpdateTrackingManager.shared.availableUpdates
        }
        let updateCount = updates.count
        guard updateCount > 0 else {
            return .result(value: "No updates available")
        }
        await MainActor.run {
            for update in updates {
                guard let downloadURLString = update.downloadURL,
                      let downloadURL = URL(string: downloadURLString) else { continue }
                let downloadId = "PortalShortcutUpdate_\(UUID().uuidString)"
                _ = DownloadManager.shared.startDownload(from: downloadURL, id: downloadId)
                AppUpdateTrackingManager.shared.updateLastKnownVersion(
                    bundleIdentifier: update.bundleIdentifier,
                    version: update.newVersion
                )
            }
        }
        return .result(value: "Updating \(updateCount) app\(updateCount == 1 ? "" : "s")")
    }
}

struct CheckPortalUpdatesIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Portal Updates"
    static var description = IntentDescription("Checks for available app updates and returns the update count")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        await MainActor.run {
            if let url = URL(string: "portal://checkupdates") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        let updates = await MainActor.run {
            AppUpdateTrackingManager.shared.availableUpdates
        }
        if updates.isEmpty {
            return .result(value: "No updates available")
        }
        let list = updates.map { "\($0.appName) (\($0.currentVersion) → \($0.newVersion))" }.joined(separator: "\n")
        return .result(value: "\(updates.count) update\(updates.count == 1 ? "" : "s") available:\n\(list)")
    }
}

// MARK: - Source Management Intents

struct AddPortalSourceIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Portal Source"
    static var description = IntentDescription("Adds a new source repository to Portal")
    static var openAppWhenRun = true

    @Parameter(title: "Source URL", description: "The URL of the source repository to add")
    var sourceURL: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmed = sourceURL.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw $sourceURL.needsValueError("Please provide a source URL")
        }
        guard URL(string: trimmed) != nil else {
            throw $sourceURL.needsValueError("Please provide a valid URL")
        }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        await MainActor.run {
            if let url = URL(string: "portal://addsource?url=\(encoded)") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result(value: "Adding source: \(trimmed)")
    }
}

struct RemovePortalSourceIntent: AppIntent {
    static var title: LocalizedStringResource = "Remove Portal Source"
    static var description = IntentDescription("Removes a source repository from Portal by its ID")
    static var openAppWhenRun = true

    @Parameter(title: "Source ID", description: "The identifier of the source to remove")
    var sourceID: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmed = sourceID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw $sourceID.needsValueError("Please provide a Source ID")
        }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        await MainActor.run {
            if let url = URL(string: "portal://removesource?id=\(encoded)") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result(value: "Removing source: \(trimmed)")
    }
}

struct RefreshPortalSourcesIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Portal Sources"
    static var description = IntentDescription("Refreshes all source repositories in Portal")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let sourceCount = await MainActor.run {
            Storage.shared.getSources().count
        }
        await MainActor.run {
            if let url = URL(string: "portal://refreshsources") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result(value: "Refreshing \(sourceCount) source\(sourceCount == 1 ? "" : "s")")
    }
}

struct RefreshPortalSourceIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Portal Source"
    static var description = IntentDescription("Refreshes a specific source repository in Portal")
    static var openAppWhenRun = true

    @Parameter(title: "Source ID", description: "The identifier of the source to refresh")
    var sourceID: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmed = sourceID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw $sourceID.needsValueError("Please provide a Source ID")
        }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        await MainActor.run {
            if let url = URL(string: "portal://refreshsource?id=\(encoded)") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result(value: "Refreshing source: \(trimmed)")
    }
}

struct ImportPortalRepoIntent: AppIntent {
    static var title: LocalizedStringResource = "Import Portal Repository"
    static var description = IntentDescription("Imports a repository into Portal from a JSON URL")
    static var openAppWhenRun = true

    @Parameter(title: "Repository URL", description: "The URL of the repository JSON to import")
    var repoURL: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmed = repoURL.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw $repoURL.needsValueError("Please provide a repository URL")
        }
        guard URL(string: trimmed) != nil else {
            throw $repoURL.needsValueError("Please provide a valid URL")
        }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        await MainActor.run {
            if let url = URL(string: "portal://importrepo?url=\(encoded)") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result(value: "Importing repository: \(trimmed)")
    }
}

struct ExportPortalSourcesIntent: AppIntent {
    static var title: LocalizedStringResource = "Export Portal Sources"
    static var description = IntentDescription("Returns a list of all sources currently added to Portal")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let sources = await MainActor.run {
            Storage.shared.getSources()
        }
        if sources.isEmpty {
            return .result(value: "No sources added")
        }
        let list = sources.compactMap { source -> String? in
            let name = source.name ?? "Unnamed"
            let urlString = source.sourceURL?.absoluteString ?? ""
            return "\(name): \(urlString)"
        }.joined(separator: "\n")
        return .result(value: "\(sources.count) source\(sources.count == 1 ? "" : "s"):\n\(list)")
    }
}

// MARK: - Library Intents

struct GetInstalledPortalAppsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Installed Portal Apps"
    static var description = IntentDescription("Returns a list of all apps installed in Portal's library")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let (signed, imported) = await MainActor.run {
            (Storage.shared.getSignedApps(), Storage.shared.getAllImportedApps())
        }
        let total = signed.count + imported.count
        if total == 0 {
            return .result(value: "No apps installed")
        }
        var lines: [String] = []
        for app in signed {
            let name = app.name ?? "Unknown"
            let version = app.version ?? ""
            let id = app.identifier ?? ""
            lines.append("\(name) \(version) (\(id)) [Signed]")
        }
        for app in imported {
            let name = app.name ?? "Unknown"
            let version = app.version ?? ""
            let id = app.identifier ?? ""
            lines.append("\(name) \(version) (\(id)) [Imported]")
        }
        return .result(value: "\(total) installed app\(total == 1 ? "" : "s"):\n\(lines.joined(separator: "\n"))")
    }
}

struct GetPortalAvailableUpdatesIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Portal Available Updates"
    static var description = IntentDescription("Returns a list of apps that have updates available in Portal")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let updates = await MainActor.run {
            AppUpdateTrackingManager.shared.availableUpdates
        }
        if updates.isEmpty {
            return .result(value: "No updates available")
        }
        let list = updates.map { "\($0.appName): \($0.currentVersion) → \($0.newVersion)" }.joined(separator: "\n")
        return .result(value: "\(updates.count) update\(updates.count == 1 ? "" : "s") available:\n\(list)")
    }
}

struct SearchPortalAppsIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Portal Apps"
    static var description = IntentDescription("Searches for apps across all Portal sources")
    static var openAppWhenRun = true

    @Parameter(title: "Query", description: "The search term to look for")
    var query: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw $query.needsValueError("Please provide a search term")
        }
        let results = await MainActor.run {
            SourcesViewModel.shared.searchApps(query: trimmed)
        }
        if results.isEmpty {
            return .result(value: "No apps found for '\(trimmed)'")
        }
        let list = results.prefix(20).map { "\($0.app.name ?? "Unknown") (\($0.source.name ?? "Unknown Source"))" }.joined(separator: "\n")
        let suffix = results.count > 20 ? "\n...and \(results.count - 20) more" : ""
        return .result(value: "\(results.count) result\(results.count == 1 ? "" : "s") for '\(trimmed)':\n\(list)\(suffix)")
    }
}

struct OpenPortalAppPageIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Portal App Page"
    static var description = IntentDescription("Navigates to an app's detail page in Portal")
    static var openAppWhenRun = true

    @Parameter(title: "App ID", description: "The bundle identifier or app ID whose page to open")
    var appID: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmed = appID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw $appID.needsValueError("Please provide an App ID")
        }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        await MainActor.run {
            if let url = URL(string: "portal://openapp?id=\(encoded)") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result(value: "Opening app page for \(trimmed)")
    }
}

// MARK: - Download Management Intents

struct PausePortalDownloadIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause Portal Download"
    static var description = IntentDescription("Pauses an active download in Portal")
    static var openAppWhenRun = true

    @Parameter(title: "App ID", description: "The app ID whose download to pause")
    var appID: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmed = appID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw $appID.needsValueError("Please provide an App ID")
        }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        await MainActor.run {
            if let url = URL(string: "portal://pausedownload?id=\(encoded)") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result(value: "Pausing download for \(trimmed)")
    }
}

struct ResumePortalDownloadIntent: AppIntent {
    static var title: LocalizedStringResource = "Resume Portal Download"
    static var description = IntentDescription("Resumes a paused download in Portal")
    static var openAppWhenRun = true

    @Parameter(title: "App ID", description: "The app ID whose download to resume")
    var appID: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmed = appID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw $appID.needsValueError("Please provide an App ID")
        }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        await MainActor.run {
            if let url = URL(string: "portal://resumedownload?id=\(encoded)") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result(value: "Resuming download for \(trimmed)")
    }
}

struct CancelPortalDownloadIntent: AppIntent {
    static var title: LocalizedStringResource = "Cancel Portal Download"
    static var description = IntentDescription("Cancels an active download in Portal")
    static var openAppWhenRun = true

    @Parameter(title: "App ID", description: "The app ID whose download to cancel")
    var appID: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmed = appID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw $appID.needsValueError("Please provide an App ID")
        }
        let cancelled = await MainActor.run { () -> Bool in
            let download = DownloadManager.shared.getDownload(by: trimmed)
            if let download {
                DownloadManager.shared.cancelDownload(download)
                return true
            }
            return false
        }
        if cancelled {
            return .result(value: "Cancelled download for \(trimmed)")
        } else {
            return .result(value: "No active download found for \(trimmed)")
        }
    }
}

struct GetActivePortalDownloadsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Active Portal Downloads"
    static var description = IntentDescription("Returns a list of currently active downloads in Portal")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let downloads = await MainActor.run {
            DownloadManager.shared.downloads
        }
        if downloads.isEmpty {
            return .result(value: "No active downloads")
        }
        let list = downloads.map { download -> String in
            let progress = Int(download.progress * 100)
            return "\(download.fileName) — \(progress)%"
        }.joined(separator: "\n")
        return .result(value: "\(downloads.count) active download\(downloads.count == 1 ? "" : "s"):\n\(list)")
    }
}

// MARK: - Navigation Intents

struct OpenPortalHomeIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Portal Home"
    static var description = IntentDescription("Navigates to the Portal home screen")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try await Task.sleep(nanoseconds: coldLaunchNavigationDelay)
        await MainActor.run {
            if let url = URL(string: "portal://home") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result()
    }
}

struct OpenPortalAppsIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Portal Apps"
    static var description = IntentDescription("Navigates to the all apps screen in Portal")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try await Task.sleep(nanoseconds: coldLaunchNavigationDelay)
        await MainActor.run {
            if let url = URL(string: "portal://apps") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result()
    }
}

struct OpenPortalInstalledIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Portal Installed Apps"
    static var description = IntentDescription("Navigates to the installed apps library in Portal")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try await Task.sleep(nanoseconds: coldLaunchNavigationDelay)
        await MainActor.run {
            if let url = URL(string: "portal://installed") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result()
    }
}

struct OpenPortalUpdatesIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Portal Updates"
    static var description = IntentDescription("Navigates to the updates screen in Portal")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try await Task.sleep(nanoseconds: coldLaunchNavigationDelay)
        await MainActor.run {
            if let url = URL(string: "portal://updates") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result()
    }
}

struct OpenPortalSourcesIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Portal Sources"
    static var description = IntentDescription("Navigates to the sources screen in Portal")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try await Task.sleep(nanoseconds: coldLaunchNavigationDelay)
        await MainActor.run {
            if let url = URL(string: "portal://sources") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result()
    }
}

struct OpenPortalSettingsIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Portal Settings"
    static var description = IntentDescription("Navigates to the settings screen in Portal")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try await Task.sleep(nanoseconds: coldLaunchNavigationDelay)
        await MainActor.run {
            if let url = URL(string: "portal://settings") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result()
    }
}

// MARK: - Maintenance Intents

struct RefreshPortalIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Portal"
    static var description = IntentDescription("Refreshes all Portal sources and checks for updates")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        await MainActor.run {
            if let url = URL(string: "portal://refreshsources") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result(value: "Refreshing Portal sources")
    }
}

struct ClearPortalCacheIntent: AppIntent {
    static var title: LocalizedStringResource = "Clear Portal Cache"
    static var description = IntentDescription("Clears the Portal work cache to free up temporary storage")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        await MainActor.run {
            if let url = URL(string: "portal://clearcache") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result(value: "Portal cache cleared")
    }
}

struct ResetPortalSourcesIntent: AppIntent {
    static var title: LocalizedStringResource = "Reset Portal Sources"
    static var description = IntentDescription("Resets all Portal sources to defaults")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        await MainActor.run {
            if let url = URL(string: "portal://resetsources") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result(value: "Resetting Portal sources")
    }
}

struct PortalDiagnosticsIntent: AppIntent {
    static var title: LocalizedStringResource = "Portal Diagnostics"
    static var description = IntentDescription("Returns diagnostic information including source count, installed apps, and update count")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let (sourceCount, signedCount, importedCount, updateCount) = await MainActor.run {
            let sources = Storage.shared.getSources().count
            let signed = Storage.shared.getSignedApps().count
            let imported = Storage.shared.getAllImportedApps().count
            let updates = AppUpdateTrackingManager.shared.availableUpdates.count
            return (sources, signed, imported, updates)
        }
        let totalInstalled = signedCount + importedCount
        let report = """
        Portal Diagnostics
        ─────────────────
        Sources: \(sourceCount)
        Installed Apps: \(totalInstalled) (\(signedCount) signed, \(importedCount) imported)
        Available Updates: \(updateCount)
        """
        return .result(value: report)
    }
}

struct ReloadPortalUIIntent: AppIntent {
    static var title: LocalizedStringResource = "Reload Portal UI"
    static var description = IntentDescription("Forces Portal to reload its user interface")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        await MainActor.run {
            if let url = URL(string: "portal://reloadui") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result(value: "Portal UI reloaded")
    }
}

// MARK: - Advanced Intents

struct InstallPortalFromURLIntent: AppIntent {
    static var title: LocalizedStringResource = "Install Portal App from URL"
    static var description = IntentDescription("Downloads and installs an IPA file directly from a URL")
    static var openAppWhenRun = true

    @Parameter(title: "IPA URL", description: "The direct URL to the IPA file to download and install")
    var ipaURL: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmed = ipaURL.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw $ipaURL.needsValueError("Please provide an IPA URL")
        }
        guard let downloadURL = URL(string: trimmed) else {
            throw $ipaURL.needsValueError("Please provide a valid URL")
        }
        await MainActor.run {
            _ = DownloadManager.shared.startDownload(from: downloadURL)
        }
        return .result(value: "Downloading and installing from \(trimmed)")
    }
}

struct BulkInstallPortalAppsIntent: AppIntent {
    static var title: LocalizedStringResource = "Bulk Install Portal Apps"
    static var description = IntentDescription("Installs multiple apps from Portal sources using a list of app IDs")
    static var openAppWhenRun = true

    @Parameter(title: "App IDs", description: "List of bundle identifiers or app IDs to install")
    var appIDs: [String]

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let filtered = appIDs.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard !filtered.isEmpty else {
            throw $appIDs.needsValueError("Please provide at least one App ID")
        }
        for (index, appID) in filtered.enumerated() {
            let encoded = appID.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? appID
            await MainActor.run {
                if let url = URL(string: "portal://install?id=\(encoded)") {
                    URLSchemeHandlerManager.shared.handleURL(url)
                }
            }
            if index < filtered.count - 1 {
                try await Task.sleep(nanoseconds: 500_000_000)
            }
        }
        return .result(value: "Installing \(filtered.count) app\(filtered.count == 1 ? "" : "s"): \(filtered.joined(separator: ", "))")
    }
}

struct SharePortalAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Share Portal App"
    static var description = IntentDescription("Shares an app link from Portal using the system share sheet")
    static var openAppWhenRun = true

    @Parameter(title: "App ID", description: "The bundle identifier or app ID to share")
    var appID: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmed = appID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw $appID.needsValueError("Please provide an App ID")
        }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        await MainActor.run {
            if let url = URL(string: "portal://shareapp?id=\(encoded)") {
                URLSchemeHandlerManager.shared.handleURL(url)
            }
        }
        return .result(value: "Sharing \(trimmed)")
    }
}
