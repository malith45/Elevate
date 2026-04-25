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
