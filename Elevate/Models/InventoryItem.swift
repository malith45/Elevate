import Foundation
import Combine

struct InventoryItem: Identifiable, Codable, Equatable {
    let id: String
    let organizationId: String
    let name: String
    let category: String
    let quantity: Int
    let unitPrice: Double
    let sku: String?
}
