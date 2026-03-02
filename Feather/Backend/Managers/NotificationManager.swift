import Foundation
import UserNotifications
import UIKit

// MARK: - Notification Type
enum NotificationType: String, CaseIterable {
    case appDownloaded = "APP_DOWNLOADED"
    case appSigned = "APP_SIGNED"
    case signingFailed = "SIGNING_FAILED"
    case downloadStarted = "DOWNLOAD_STARTED"
    case downloadFailed = "DOWNLOAD_FAILED"
    case updateAvailable = "UPDATE_AVAILABLE"
    case backupSuccess = "BACKUP_SUCCESS"
    case backupFailed = "BACKUP_FAILED"
    case certExpiring = "CERT_EXPIRING"
    case lowStorage = "LOW_STORAGE"
    case securityAlert = "SECURITY_ALERT"
    case test = "TEST"

    var defaultEnabled: Bool {
        switch self {
        case .downloadStarted: return false
        default: return true
        }
    }

    var userDefaultsKey: String {
        return "Feather.notification.\(self.rawValue)"
    }
}

// MARK: - Notification Manager
final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
        setupDefaultPreferences()
    }

    private func setupDefaultPreferences() {
        for type in NotificationType.allCases {
            if UserDefaults.standard.object(forKey: type.userDefaultsKey) == nil {
                UserDefaults.standard.set(type.defaultEnabled, forKey: type.userDefaultsKey)
            }
        }
    }
    
    // MARK: - Authorization
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                self?.checkAuthorizationStatus()
                
                if let error = error {
                    AppLogManager.shared.error("Failed to request notification authorization: \(error.localizedDescription)", category: "Notifications")
                } else if granted {
                    AppLogManager.shared.success("Notification Authorization Granted", category: "Notifications")
                } else {
                    AppLogManager.shared.warning("Notification Authorization Denied", category: "Notifications")
                }
                
                completion(granted)
            }
        }
    }
    
    func checkAuthorizationStatus() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                self?.isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
            }
        }
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Send Notifications
    
    func sendAppSignedNotification(appName: String) {
        // This was historically used for "Downloaded App" in this codebase
        sendNotification(
            title: .localized("Downloaded App"),
            body: String(format: .localized("%@ was downloaded successfully. Check the Library tab to sign the app"), appName),
            type: .appDownloaded
        )
    }

    func sendAppReadyNotification(appName: String) {
        sendNotification(
            title: .localized("App Ready to Install"),
            body: String(format: .localized("%@ has been signed successfully and is ready to install."), appName),
            type: .appSigned
        )
    }

    func sendSigningFailedNotification(appName: String, error: String) {
        sendNotification(
            title: .localized("Signing Failed"),
            body: String(format: .localized("Failed to sign %@: %@"), appName, error),
            type: .signingFailed
        )
    }

    func sendDownloadStartedNotification(appName: String) {
        sendNotification(
            title: .localized("Download Started"),
            body: String(format: .localized("Started downloading %@..."), appName),
            type: .downloadStarted
        )
    }

    func sendDownloadFailedNotification(appName: String, error: String) {
        sendNotification(
            title: .localized("Download Failed"),
            body: String(format: .localized("Failed to download %@: %@"), appName, error),
            type: .downloadFailed
        )
    }

    func sendUpdateAvailableNotification(version: String) {
        sendNotification(
            title: .localized("Update Available"),
            body: String(format: .localized("A new version of Feather (%@) is available."), version),
            type: .updateAvailable
        )
    }

    func sendBackupSuccessNotification() {
        sendNotification(
            title: .localized("Backup Successful"),
            body: .localized("Your data has been backed up successfully."),
            type: .backupSuccess
        )
    }

    func sendBackupFailedNotification(error: String) {
        sendNotification(
            title: .localized("Backup Failed"),
            body: String(format: .localized("Failed to backup data: %@"), error),
            type: .backupFailed
        )
    }

    func sendCertExpiringNotification(days: Int) {
        sendNotification(
            title: .localized("Certificate Expiring"),
            body: String(format: .localized("Your certificate will expire in %d days."), days),
            type: .certExpiring
        )
    }

    func sendLowStorageNotification() {
        sendNotification(
            title: .localized("Low Storage"),
            body: .localized("Your device storage is running low. Some features may not work correctly."),
            type: .lowStorage
        )
    }

    func sendSecurityAlertNotification(message: String) {
        sendNotification(
            title: .localized("Security Alert"),
            body: message,
            type: .securityAlert
        )
    }

    func sendTestNotification() {
        sendNotification(
            title: .localized("Test Notification"),
            body: .localized("This is a test notification. Notifications are working correctly!"),
            type: .test
        )
    }

    private func sendNotification(title: String, body: String, type: NotificationType) {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()

            await MainActor.run {
                self.authorizationStatus = settings.authorizationStatus
                self.isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
            }

            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                AppLogManager.shared.warning("Cannot send notification: Not Authorized (\(settings.authorizationStatus.rawValue))", category: "Notifications")
                return
            }

            guard UserDefaults.standard.bool(forKey: "Feather.notificationsEnabled") else {
                AppLogManager.shared.warning("Notifications are disabled globally in settings", category: "Notifications")
                return
            }

            guard UserDefaults.standard.bool(forKey: type.userDefaultsKey) else {
                AppLogManager.shared.info("Notification type \(type.rawValue) is disabled by user", category: "Notifications")
                return
            }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.badge = NSNumber(value: 1)
            content.categoryIdentifier = type.rawValue

            // Trigger nil for immediate delivery
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

            do {
                try await center.add(request)
                AppLogManager.shared.success("Notification sent: \(title)", category: "Notifications")
            } catch {
                AppLogManager.shared.error("Failed to send notification: \(error.localizedDescription)", category: "Notifications")
            }
        }
    }
    
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notifications even when the app is in the foreground
        completionHandler([.banner, .list, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        let identifier = response.notification.request.content.categoryIdentifier
        
        AppLogManager.shared.info("User tapped notification: \(identifier)", category: "Notifications")
        
        completionHandler()
    }
}
