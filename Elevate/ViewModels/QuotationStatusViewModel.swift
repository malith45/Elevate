import Foundation
import Combine

final class QuotationStatusViewModel: ObservableObject {
    @Published var items: [QuotationItem] = []
    @Published var errorMessage: String?

    private let firebase = FirebaseService.shared

    var approvedItems: [QuotationItem] {
        items.filter { $0.status.uppercased() == "APPROVED" }
    }

    var pendingItems: [QuotationItem] {
        items.filter { $0.status.uppercased() != "APPROVED" }
    }

    var totalCost: Double {
        approvedItems.reduce(0) { $0 + (Double($1.quantity) * $1.unitPrice) }
    }

    func load(jobId: String) {
        firebase.fetchQuotationItems(jobId: jobId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let items):
                    self.items = items
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
