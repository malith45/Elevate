import Foundation
import Combine

final class QuotationStatusViewModel: ObservableObject {
    @Published var items: [QuotationItem] = []
    @Published var errorMessage: String?

    private let firebase = FirebaseService.shared
    private let localStorage = LocalStorageService.shared
    private let network = NetworkService.shared

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
        if let cached = localStorage.fetchJob(id: jobId)?.quotationItems {
            items = cached
        }

        guard network.isOnline else { return }

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
