import Foundation
import Combine

struct NotificationItem: Identifiable, Codable, Equatable {
    let id: String
    let organizationId: String
    let userId: String
    let title: String
    let body: String
    let type: String
    let targetId: String?
    let createdAt: Date
    let isRead: Bool
}
