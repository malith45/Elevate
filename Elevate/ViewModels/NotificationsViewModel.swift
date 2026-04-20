import Foundation
import Combine

final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    @Published var errorMessage: String?

    private let localStorage = LocalStorageService.shared
    private let firebase = FirebaseService.shared

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

        if NetworkService.shared.isOnline {
            firebase.clearNotifications(organizationId: organizationId, userId: userId) { _ in }
        } else {
            SyncManager.shared.enqueueClearNotifications(organizationId: organizationId, userId: userId)
        }
    }

    func markRead(_ item: NotificationItem, isOnline: Bool) {
        guard !item.isRead else { return }
        localStorage.markNotificationRead(id: item.id)
        notifications = notifications.map { current in
            if current.id == item.id {
                return NotificationItem(
                    id: current.id,
                    organizationId: current.organizationId,
                    userId: current.userId,
                    title: current.title,
                    body: current.body,
                    type: current.type,
                    targetId: current.targetId,
                    createdAt: current.createdAt,
                    isRead: true
                )
            }
            return current
        }

        guard isOnline else {
            SyncManager.shared.enqueueNotificationRead(notificationId: item.id, isRead: true, organizationId: item.organizationId, userId: item.userId)
            return
        }
        firebase.updateNotificationRead(notificationId: item.id, isRead: true) { _ in }
    }
}
