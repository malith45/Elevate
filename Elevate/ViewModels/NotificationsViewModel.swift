import Foundation
import Combine

final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    @Published var errorMessage: String?

    private let localStorage = LocalStorageService.shared

    var todayItems: [NotificationItem] {
        notifications.filter { Calendar.current.isDateInToday($0.createdAt) }
    }

    var yesterdayItems: [NotificationItem] {
        notifications.filter { Calendar.current.isDateInYesterday($0.createdAt) }
    }

    var olderItems: [NotificationItem] {
        notifications.filter {
            !Calendar.current.isDateInToday($0.createdAt) && !Calendar.current.isDateInYesterday($0.createdAt)
        }
    }

    func load(organizationId: String, userId: String, isOnline: Bool) {
        notifications = localStorage.fetchNotifications(organizationId: organizationId, userId: userId)

        if isOnline {
            SyncManager.shared.syncNotifications(organizationId: organizationId, userId: userId) { [weak self] in
                let refreshed = self?.localStorage.fetchNotifications(organizationId: organizationId, userId: userId) ?? []
                DispatchQueue.main.async {
                    self?.notifications = refreshed
                }
            }
        }
    }

    func clearAll(organizationId: String, userId: String) {
        localStorage.clearNotifications(organizationId: organizationId, userId: userId)
        notifications = []
    }
}
