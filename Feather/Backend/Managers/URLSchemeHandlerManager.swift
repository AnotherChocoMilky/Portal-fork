import Foundation
import SwiftUI

/// Centralized manager that parses incoming `portal://` URLs, validates parameters,
/// and routes the action to the correct internal feature.
final class URLSchemeHandlerManager: ObservableObject {
    static let shared = URLSchemeHandlerManager()

    // MARK: - Scheme Result

    enum SchemeResult {
        case success
        case missingParameter(String)
        case unknownScheme(String)
        case invalidURL
    }

    private init() {}

    // MARK: - Public API

    /// Parses and handles an incoming `portal://` URL.
    /// Returns a ``SchemeResult`` indicating whether the action succeeded.
    @discardableResult
    func handleURL(_ url: URL) -> SchemeResult {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "portal" || scheme == "feather" else {
            return .invalidURL
        }

        guard let host = url.host?.lowercased() else {
            return .invalidURL
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        func queryValue(_ name: String) -> String? {
            queryItems.first(where: { $0.name == name })?.value?.removingPercentEncoding
        }

        switch host {

        // MARK: Core Actions

        case "open", "home":
            switchTab(.dashboard)
            return .success

        case "search":
            switchTab(.sources)
            return .success

        case "refreshsources":
            NotificationCenter.default.post(name: Notification.Name("Portal.RefreshSources"), object: nil)
            return .success

        case "checkupdates":
            NotificationCenter.default.post(name: Notification.Name("Portal.CheckUpdates"), object: nil)
            return .success

        // MARK: Source Management

        case "sources":
            switchTab(.sources)
            return .success

        case "addsource":
            guard let urlString = queryValue("url"), !urlString.isEmpty else {
                return .missingParameter("url")
            }
            NotificationCenter.default.post(name: Notification.Name("Portal.AddSource"), object: urlString)
            return .success

        case "removesource":
            guard let sourceID = queryValue("id"), !sourceID.isEmpty else {
                return .missingParameter("id")
            }
            NotificationCenter.default.post(name: Notification.Name("Portal.RemoveSource"), object: sourceID)
            return .success

        case "editsource":
            guard let sourceID = queryValue("id"), !sourceID.isEmpty else {
                return .missingParameter("id")
            }
            NotificationCenter.default.post(name: Notification.Name("Portal.EditSource"), object: sourceID)
            return .success

        case "refreshsource":
            guard let sourceID = queryValue("id"), !sourceID.isEmpty else {
                return .missingParameter("id")
            }
            NotificationCenter.default.post(name: Notification.Name("Portal.RefreshSource"), object: sourceID)
            return .success

        // MARK: App Management

        case "install":
            guard let appID = queryValue("id"), !appID.isEmpty else {
                return .missingParameter("id")
            }
            NotificationCenter.default.post(name: Notification.Name("Portal.InstallApp"), object: appID)
            return .success

        case "download":
            guard let appID = queryValue("id"), !appID.isEmpty else {
                return .missingParameter("id")
            }
            NotificationCenter.default.post(name: Notification.Name("Portal.DownloadApp"), object: appID)
            return .success

        case "openapp":
            guard let appID = queryValue("id"), !appID.isEmpty else {
                return .missingParameter("id")
            }
            NotificationCenter.default.post(name: Notification.Name("Portal.OpenApp"), object: appID)
            return .success

        case "uninstall":
            guard let appID = queryValue("id"), !appID.isEmpty else {
                return .missingParameter("id")
            }
            NotificationCenter.default.post(name: Notification.Name("Portal.UninstallApp"), object: appID)
            return .success

        case "reinstall":
            guard let appID = queryValue("id"), !appID.isEmpty else {
                return .missingParameter("id")
            }
            NotificationCenter.default.post(name: Notification.Name("Portal.ReinstallApp"), object: appID)
            return .success

        case "updateapp":
            guard let appID = queryValue("id"), !appID.isEmpty else {
                return .missingParameter("id")
            }
            NotificationCenter.default.post(name: Notification.Name("Portal.UpdateApp"), object: appID)
            return .success

        case "pausedownload":
            guard let appID = queryValue("id"), !appID.isEmpty else {
                return .missingParameter("id")
            }
            NotificationCenter.default.post(name: Notification.Name("Portal.PauseDownload"), object: appID)
            return .success

        case "resumedownload":
            guard let appID = queryValue("id"), !appID.isEmpty else {
                return .missingParameter("id")
            }
            NotificationCenter.default.post(name: Notification.Name("Portal.ResumeDownload"), object: appID)
            return .success

        // MARK: Navigation

        case "apps":
            switchTab(.allapps)
            return .success

        case "installed":
            switchTab(.library)
            return .success

        case "updates":
            switchTab(.settings)
            NotificationCenter.default.post(name: Notification.Name("Portal.NavigateToUpdates"), object: nil)
            return .success

        case "library":
            switchTab(.library)
            return .success

        case "settings":
            switchTab(.settings)
            return .success

        // MARK: Advanced Utilities

        case "clearcache":
            ResetView.clearWorkCache()
            HapticsManager.shared.success()
            return .success

        case "resetsources":
            NotificationCenter.default.post(name: Notification.Name("Portal.ResetSources"), object: nil)
            return .success

        case "logs":
            if let logsData = try? JSONEncoder().encode(AppLogManager.shared.logs) {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("PortalLogs.json")
                try? logsData.write(to: tempURL)
                DispatchQueue.main.async {
                    UIActivityViewController.show(activityItems: [tempURL])
                }
            }
            return .success

        case "reloadui":
            NotificationCenter.default.post(name: Notification.Name("Portal.ReloadUI"), object: nil)
            return .success

        case "diagnostics":
            NotificationCenter.default.post(name: Notification.Name("Portal.Diagnostics"), object: nil)
            return .success

        // MARK: External Integration

        case "importrepo":
            guard let urlString = queryValue("url"), !urlString.isEmpty else {
                return .missingParameter("url")
            }
            NotificationCenter.default.post(name: Notification.Name("Portal.ImportRepo"), object: urlString)
            return .success

        case "shareapp":
            guard let appID = queryValue("id"), !appID.isEmpty else {
                return .missingParameter("id")
            }
            NotificationCenter.default.post(name: Notification.Name("Portal.ShareApp"), object: appID)
            return .success

        case "openrepo":
            guard let repoID = queryValue("id"), !repoID.isEmpty else {
                return .missingParameter("id")
            }
            NotificationCenter.default.post(name: Notification.Name("Portal.OpenRepo"), object: repoID)
            return .success

        case "installfromurl":
            guard let ipaURLString = queryValue("ipa"), !ipaURLString.isEmpty,
                  let downloadURL = URL(string: ipaURLString) else {
                return .missingParameter("ipa")
            }
            _ = DownloadManager.shared.startDownload(from: downloadURL)
            return .success

        default:
            return .unknownScheme(host)
        }
    }

    // MARK: - Helpers

    private func switchTab(_ tab: TabEnum) {
        NotificationCenter.default.post(name: Notification.Name("Feather.SwitchTab"), object: tab)
    }

    // MARK: - Supported Schemes (used by URLSchemeView)

    struct SchemeInfo: Identifiable {
        let id = UUID()
        let scheme: String
        let example: String
        let description: String
    }

    static let coreActions: [SchemeInfo] = [
        SchemeInfo(scheme: "portal://open", example: "portal://open", description: "Opens the app to the home screen."),
        SchemeInfo(scheme: "portal://home", example: "portal://home", description: "Navigates to the home dashboard."),
        SchemeInfo(scheme: "portal://search", example: "portal://search", description: "Opens the sources tab for searching apps."),
        SchemeInfo(scheme: "portal://refreshSources", example: "portal://refreshSources", description: "Refreshes all configured sources."),
        SchemeInfo(scheme: "portal://checkUpdates", example: "portal://checkUpdates", description: "Checks for available app updates."),
    ]

    static let sourceManagement: [SchemeInfo] = [
        SchemeInfo(scheme: "portal://sources", example: "portal://sources", description: "Opens the sources list."),
        SchemeInfo(scheme: "portal://addSource?url=", example: "portal://addSource?url=https://example.com/repo", description: "Adds a new source from the given URL."),
        SchemeInfo(scheme: "portal://removeSource?id=", example: "portal://removeSource?id=source123", description: "Removes the source with the specified ID."),
        SchemeInfo(scheme: "portal://editSource?id=", example: "portal://editSource?id=source123", description: "Opens the editor for the specified source."),
        SchemeInfo(scheme: "portal://refreshSource?id=", example: "portal://refreshSource?id=source123", description: "Refreshes a single source by its ID."),
    ]

    static let appManagement: [SchemeInfo] = [
        SchemeInfo(scheme: "portal://install?id=", example: "portal://install?id=com.example.app", description: "Installs the app with the given identifier."),
        SchemeInfo(scheme: "portal://download?id=", example: "portal://download?id=com.example.app", description: "Downloads the app without installing it."),
        SchemeInfo(scheme: "portal://openApp?id=", example: "portal://openApp?id=com.example.app", description: "Opens an installed app by its identifier."),
        SchemeInfo(scheme: "portal://uninstall?id=", example: "portal://uninstall?id=com.example.app", description: "Uninstalls the specified app."),
        SchemeInfo(scheme: "portal://reinstall?id=", example: "portal://reinstall?id=com.example.app", description: "Reinstalls the specified app."),
        SchemeInfo(scheme: "portal://updateApp?id=", example: "portal://updateApp?id=com.example.app", description: "Updates the specified app to the latest version."),
        SchemeInfo(scheme: "portal://pauseDownload?id=", example: "portal://pauseDownload?id=com.example.app", description: "Pauses an active download."),
        SchemeInfo(scheme: "portal://resumeDownload?id=", example: "portal://resumeDownload?id=com.example.app", description: "Resumes a paused download."),
    ]

    static let navigation: [SchemeInfo] = [
        SchemeInfo(scheme: "portal://apps", example: "portal://apps", description: "Shows all available apps."),
        SchemeInfo(scheme: "portal://installed", example: "portal://installed", description: "Shows installed apps in the library."),
        SchemeInfo(scheme: "portal://updates", example: "portal://updates", description: "Navigates to the updates section."),
        SchemeInfo(scheme: "portal://library", example: "portal://library", description: "Opens the app library."),
        SchemeInfo(scheme: "portal://settings", example: "portal://settings", description: "Opens the settings screen."),
    ]

    static let advancedUtilities: [SchemeInfo] = [
        SchemeInfo(scheme: "portal://clearCache", example: "portal://clearCache", description: "Clears the app work cache."),
        SchemeInfo(scheme: "portal://resetSources", example: "portal://resetSources", description: "Resets all configured sources."),
        SchemeInfo(scheme: "portal://logs", example: "portal://logs", description: "Exports app logs as a JSON file."),
        SchemeInfo(scheme: "portal://reloadUI", example: "portal://reloadUI", description: "Forces a UI reload."),
        SchemeInfo(scheme: "portal://diagnostics", example: "portal://diagnostics", description: "Opens the diagnostics view."),
    ]

    static let externalIntegration: [SchemeInfo] = [
        SchemeInfo(scheme: "portal://importRepo?url=", example: "portal://importRepo?url=https://example.com/repo.json", description: "Imports a repository from the given URL."),
        SchemeInfo(scheme: "portal://shareApp?id=", example: "portal://shareApp?id=com.example.app", description: "Shares the specified app."),
        SchemeInfo(scheme: "portal://openRepo?id=", example: "portal://openRepo?id=repo123", description: "Opens a repository by its identifier."),
        SchemeInfo(scheme: "portal://installFromURL?ipa=", example: "portal://installFromURL?ipa=https://example.com/app.ipa", description: "Downloads and installs an IPA from a direct URL."),
    ]
}
