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
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
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

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Extract data from root or 'data' or 'gcm.notification.data'
        var data = userInfo
        if let customData = userInfo["data"] as? [AnyHashable: Any] {
            data = customData
        }
        
        let type = data["type"] as? String ?? userInfo["type"] as? String ?? "NOTIFICATION"
        let targetId = data["targetId"] as? String ?? userInfo["targetId"] as? String
        
        DispatchQueue.main.async {
            if let userId = SessionStore.shared.getUserId(),
               let user = LocalStorageService.shared.fetchUser(id: userId) {
                if user.role.uppercased() == "MANAGER" {
                    ManagerTabRouter.shared.handleDeepLink(type: type, targetId: targetId)
                } else {
                    TechnicianTabRouter.shared.handleDeepLink(type: type, targetId: targetId)
                }
            }
        }
        
        completionHandler()
    }
}
