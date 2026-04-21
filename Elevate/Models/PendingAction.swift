import Foundation
import Combine

enum PendingActionType: String, Codable {
    case createJob
    case updateJobStatus
    case updateJobFields
    case deleteJob
    case submitQuotationRequest
    case updateQuotationItems
    case createInventoryItem
    case updateInventoryItem
    case deleteInventoryItem
    case updateUserProfile
    case deleteUserProfile
    case markNotificationRead
    case clearNotifications
}

struct PendingAction: Identifiable, Codable, Equatable {
    let id: String
    let organizationId: String
    let userId: String
    let type: PendingActionType
    let payload: Data
    let createdAt: Date
}
