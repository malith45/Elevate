import Foundation
import Combine

struct QuotationItem: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let unitPrice: Double
    let quantity: Int
    let status: String
}
