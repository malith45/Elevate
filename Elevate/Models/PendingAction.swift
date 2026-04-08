import Foundation
import Combine

enum PendingActionType: String, Codable {
    case updateJobStatus
    case updateJobFields
    case submitQuotationRequest
}

struct PendingAction: Identifiable, Codable, Equatable {
    let id: String
    let organizationId: String
    let userId: String
    let type: PendingActionType
    let payload: Data
    let createdAt: Date
}
