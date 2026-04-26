import Foundation

struct Job: Identifiable, Codable, Equatable {
    let id: String
    let organizationId: String
    var title: String
    var location: String
    var siteLatitude: Double?
    var siteLongitude: Double?
    var scheduledAt: Date
    var status: String
    var priority: String
    var isUrgent: Bool
    var isOnHold: Bool
    var holdReason: String?
    var cancelledAt: Date?
    let assignedUserId: String
    var notes: String?
    var quotationItems: [QuotationItem]
    var approvedCost: Double?
    var photoUrls: [String]
    var updatedAt: Date
}

extension Job {
    var isOverdue: Bool {
        let statusUpper = status.uppercased()
        let isTerminal = statusUpper == "COMPLETED" || statusUpper == "CANCELLED"
        let isInProgress = statusUpper == "IN-PROGRESS"
        
        // If it's not completed/cancelled/in-progress and the scheduled date is more than 30 mins in the past
        // We add a 30-min grace period or just any past date.
        // The user said "past the scheduled date".
        return !isTerminal && !isInProgress && scheduledAt < Date()
    }
}

typealias AppJob = Job
