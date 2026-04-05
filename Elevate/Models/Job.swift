import Foundation

struct Job: Identifiable, Codable, Equatable {
    let id: String
    let organizationId: String
    let title: String
    let location: String
    let scheduledAt: Date
    let status: String
    let priority: String
    let assignedUserId: String
    let notes: String?
    let approvedCost: Double?
    let photoUrls: [String]
    let updatedAt: Date
}
