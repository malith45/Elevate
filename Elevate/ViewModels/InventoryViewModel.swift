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

        let mergedItems = mergeQuotationItems(jobId: jobId, newItems: selected)
        localStorage.updateJobQuotationItems(id: jobId, items: mergedItems, updatedAt: Date())

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

    private func mergeQuotationItems(jobId: String, newItems: [QuotationItem]) -> [QuotationItem] {
        guard var existing = localStorage.fetchJob(id: jobId)?.quotationItems else {
            return newItems
        }

        newItems.forEach { newItem in
            if let index = existing.firstIndex(where: { $0.id == newItem.id }) {
                existing[index] = newItem
            } else {
                existing.append(newItem)
            }
        }

        return existing
    }

    func createItem(organizationId: String, name: String, category: String, quantity: Int, unitPrice: Double, sku: String?, isOnline: Bool, completion: @escaping (InventoryItem?) -> Void) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Item name is required."
            completion(nil)
            return
        }
        guard !trimmedCategory.isEmpty else {
            errorMessage = "Category is required."
            completion(nil)
            return
        }

        let item = InventoryItem(
            id: UUID().uuidString,
            organizationId: organizationId,
            name: trimmedName,
            category: trimmedCategory,
            quantity: max(0, quantity),
            unitPrice: max(0, unitPrice),
            sku: sku?.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        localStorage.saveInventoryItems([item])
        items = localStorage.fetchInventoryItems(organizationId: organizationId)

        guard isOnline else {
            completion(item)
            return
        }

        firebase.createInventoryItem(item) { result in
            DispatchQueue.main.async {
                if case .failure(let error) = result {
                    self.errorMessage = error.localizedDescription
                    completion(nil)
                } else {
                    completion(item)
                }
            }
        }
    }

    func updateItem(_ item: InventoryItem, name: String, category: String, quantity: Int, unitPrice: Double, sku: String?, isOnline: Bool, completion: @escaping (InventoryItem?) -> Void) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Item name is required."
            completion(nil)
            return
        }
        guard !trimmedCategory.isEmpty else {
            errorMessage = "Category is required."
            completion(nil)
            return
        }

        let updated = InventoryItem(
            id: item.id,
            organizationId: item.organizationId,
            name: trimmedName,
            category: trimmedCategory,
            quantity: max(0, quantity),
            unitPrice: max(0, unitPrice),
            sku: sku?.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        localStorage.saveInventoryItems([updated])
        items = localStorage.fetchInventoryItems(organizationId: item.organizationId)

        guard isOnline else {
            completion(updated)
            return
        }

        let fields: [String: Any] = [
            "name": updated.name,
            "category": updated.category,
            "quantity": updated.quantity,
            "unitPrice": updated.unitPrice,
            "sku": updated.sku as Any
        ]

        firebase.updateInventoryItem(itemId: item.id, fields: fields) { result in
            DispatchQueue.main.async {
                if case .failure(let error) = result {
                    self.errorMessage = error.localizedDescription
                    completion(nil)
                } else {
                    completion(updated)
                }
            }
        }
    }
}
