import Foundation
import Combine

struct IssueReport: Identifiable, Codable, Equatable {
    let id: String
    let jobId: String
    let userId: String
    let organizationId: String
    let description: String
    let priority: String
    let createdAt: Date
    let attachmentUrls: [String]
}
