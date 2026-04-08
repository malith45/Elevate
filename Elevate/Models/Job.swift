import Foundation

struct Job: Identifiable, Codable, Equatable {
    let id: String
    let organizationId: String
    let title: String
    let location: String
    let siteLatitude: Double?
    let siteLongitude: Double?
    let scheduledAt: Date
    let status: String
    let priority: String
    let isUrgent: Bool
    let isOnHold: Bool
    let holdReason: String?
    let cancelledAt: Date?
    let assignedUserId: String
    let notes: String?
    let quotationItems: [QuotationItem]
    let approvedCost: Double?
    let photoUrls: [String]
    let updatedAt: Date
}
