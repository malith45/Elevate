import Foundation
import Combine
import UserNotifications
import FirebaseMessaging
import UIKit

extension Notification.Name {
    static let notificationsDidChange = Notification.Name("notificationsDidChange")
    static let jobStatusDidChange = Notification.Name("jobStatusDidChange")
}

final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    static let shared = NotificationService()

    @Published private(set) var fcmToken: String?

    private override init() {
        super.init()
    }

    func configure() {
        // Delegates are now handled by AppDelegate
        requestAuthorization()
    }

    private func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        self.fcmToken = fcmToken
        if let token = fcmToken {
            UserDefaults.standard.set(token, forKey: "fcmToken")
        }
    }

    func notificationToken() -> String? {
        fcmToken ?? UserDefaults.standard.string(forKey: "fcmToken")
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        DispatchQueue.main.async {
            HapticManager.shared.playNotification(type: .success)
            SoundManager.shared.playNotificationSound()
        }
        completionHandler([.banner, .sound, .list])
    }
}
