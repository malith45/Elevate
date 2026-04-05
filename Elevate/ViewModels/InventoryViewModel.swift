import Foundation
import Combine

final class InventoryViewModel: ObservableObject {
    @Published var items: [InventoryItem] = []
    @Published var quantities: [String: Int] = [:]
    @Published var errorMessage: String?

    private let localStorage = LocalStorageService.shared
    private let firebase = FirebaseService.shared

    func loadItems(organizationId: String, isOnline: Bool) {
        items = localStorage.fetchInventoryItems(organizationId: organizationId)
        if isOnline {
            firebase.fetchInventoryItems(organizationId: organizationId) { result in
                if case .success(let fetched) = result {
                    self.localStorage.saveInventoryItems(fetched)
                    DispatchQueue.main.async {
                        self.items = fetched
                    }
                }
            }
        }
    }

    func quantity(for itemId: String) -> Int {
        quantities[itemId, default: 0]
    }

    func increment(itemId: String) {
        quantities[itemId, default: 0] += 1
    }

    func decrement(itemId: String) {
        let current = quantities[itemId, default: 0]
        quantities[itemId] = max(current - 1, 0)
    }

    func selectedQuotationItems() -> [QuotationItem] {
        items.compactMap { item in
            let qty = quantities[item.id, default: 0]
            guard qty > 0 else { return nil }
            return QuotationItem(
                id: item.id,
                name: item.name,
                unitPrice: item.unitPrice,
                quantity: qty,
                status: "PENDING"
            )
        }
    }

    func submitQuotationRequest(jobId: String, userId: String, organizationId: String, isOnline: Bool) {
        let selected = selectedQuotationItems()
        guard !selected.isEmpty else {
            errorMessage = "Select at least one item."
            return
        }
        if isOnline {
            firebase.submitQuotationRequest(jobId: jobId, userId: userId, items: selected) { result in
                if case .failure(let error) = result {
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        } else {
            SyncManager.shared.enqueueQuotationRequest(
                jobId: jobId,
                userId: userId,
                organizationId: organizationId,
                items: selected
            )
        }
    }
}
