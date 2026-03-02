import Foundation
import UserNotifications
import UIKit

// MARK: - Notification Manager
final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
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
                self?.isAuthorized = settings.authorizationStatus == .authorized
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
        sendNotification(
            title: "Downloaded App",
            body: "\(appName) was downloaded successfully. Check the Library tab to sign the app",
            category: "APP_SIGNED"
        )
    }

    func sendAppReadyNotification(appName: String) {
        sendNotification(
            title: "App Ready to Install",
            body: "\(appName) has been signed successfully and is ready to install.",
            category: "APP_READY"
        )
    }

    func sendTestNotification() {
        sendNotification(
            title: "Test Notification",
            body: "This is a test notification from Portal. If you see this, notifications are working correctly!",
            category: "TEST"
        )
    }

    private func sendNotification(title: String, body: String, category: String) {
        // Check authorization before sending
        checkAuthorizationStatus()
        
        guard UserDefaults.standard.bool(forKey: "Feather.notificationsEnabled") else {
            AppLogManager.shared.warning("Notifications are disabled in settings", category: "Notifications")
            return
        }
        
        guard isAuthorized else {
            AppLogManager.shared.warning("Cannot send notification: Not Authorized", category: "Notifications")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = category
        
        // Use a very short trigger to send immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                AppLogManager.shared.error("Failed to send notification: \(error.localizedDescription)", category: "Notifications")
            } else {
                AppLogManager.shared.success("Notification sent: \(title)", category: "Notifications")
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
        
        if identifier == "APP_READY" || identifier == "APP_SIGNED" {
            // Potentially switch to a specific tab or perform an action
            AppLogManager.shared.info("User tapped notification: \(identifier)", category: "Notifications")
        }
        
        completionHandler()
    }
}
