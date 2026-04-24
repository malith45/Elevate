import Foundation
import Combine

struct User: Identifiable, Codable, Equatable {
    let id: String
    let organizationId: String
    let username: String
    let displayName: String
    let role: String
    let email: String?
    let phone: String?
    let latitude: Double?
    let longitude: Double?
    let notificationsEnabled: Bool
}
