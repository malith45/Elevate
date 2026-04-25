import Foundation
import Combine
import FirebaseFirestore

final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    @Published var errorMessage: String?

    private let localStorage = LocalStorageService.shared
    private let firebase = FirebaseService.shared
    private var notificationsListener: ListenerRegistration?

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
        // Show cached data immediately
        notifications = localStorage.fetchNotifications(organizationId: organizationId, userId: userId)

        guard isOnline else { return }

        // Real-time listener — fires on any add, update, or delete in Firebase
        notificationsListener?.remove()
        notificationsListener = firebase.listenToNotifications(
            organizationId: organizationId,
            userId: userId
        ) { [weak self] remoteItems in
            guard let self = self else { return }

            // Purge locally cached notifications no longer in Firebase
            let remoteIds = Set(remoteItems.map { $0.id })
            let localItems = self.localStorage.fetchNotifications(organizationId: organizationId, userId: userId)
            for localItem in localItems where !remoteIds.contains(localItem.id) {
                // Mark as cleared by deleting individually
                // (clearNotifications is bulk; here we need per-item deletion)
                self.localStorage.deleteNotification(id: localItem.id)
            }

            // Upsert the latest remote state
            self.localStorage.saveNotifications(remoteItems)

            DispatchQueue.main.async {
                var seen = Set<String>()
                self.notifications = remoteItems
                    .filter { seen.insert($0.id).inserted }
                    .sorted(by: { $0.createdAt > $1.createdAt })
            }
        }
    }

    func markAllRead(organizationId: String, userId: String) {
        let unread = notifications.filter { !$0.isRead }
        guard !unread.isEmpty else { return }
        
        unread.forEach { markRead($0, isOnline: NetworkService.shared.isOnline) }
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

    deinit {
        notificationsListener?.remove()
    }
}
