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
        applyInventoryReductions(items: selected, organizationId: organizationId, userId: userId, isOnline: isOnline)

        if isOnline {
            firebase.submitQuotationRequest(jobId: jobId, userId: userId, items: selected) { result in
                if case .failure(let error) = result {
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                    }
                } else {
                    self.notifyManagersForQuotation(jobId: jobId, organizationId: organizationId, userId: userId)
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

    private func applyInventoryReductions(items: [QuotationItem], organizationId: String, userId: String, isOnline: Bool) {
        var updatedInventory: [InventoryItem] = []

        items.forEach { item in
            guard let inventoryItem = localStorage.fetchInventoryItem(id: item.id) else { return }
            let newQuantity = max(0, inventoryItem.quantity - item.quantity)
            localStorage.updateInventoryQuantity(itemId: inventoryItem.id, quantity: newQuantity)

            let updated = InventoryItem(
                id: inventoryItem.id,
                organizationId: inventoryItem.organizationId,
                name: inventoryItem.name,
                category: inventoryItem.category,
                quantity: newQuantity,
                unitPrice: inventoryItem.unitPrice,
                sku: inventoryItem.sku,
                imageUrl: inventoryItem.imageUrl
            )
            updatedInventory.append(updated)

            let fields: [String: Any] = ["quantity": newQuantity]
            if isOnline {
                firebase.updateInventoryItem(itemId: inventoryItem.id, fields: fields) { _ in }
            } else {
                SyncManager.shared.enqueueUpdateInventoryItem(itemId: inventoryItem.id, fields: fields, organizationId: organizationId, userId: userId)
            }
        }

        if !updatedInventory.isEmpty {
            localStorage.saveInventoryItems(updatedInventory)
            self.items = localStorage.fetchInventoryItems(organizationId: organizationId)
        }
    }

    private func notifyManagersForQuotation(jobId: String, organizationId: String, userId: String) {
        let managers = localStorage.fetchUsers(organizationId: organizationId)
            .filter { $0.role.uppercased() == "MANAGER" }
        guard !managers.isEmpty else { return }

        let technicianName = localStorage.fetchUser(id: userId)?.displayName
        let jobTitle = localStorage.fetchJob(id: jobId)?.title ?? "Job"
        let title = "Quotation submitted"
        let body = "\(technicianName?.isEmpty == false ? technicianName! : "Technician") sent items for \(jobTitle)."

        managers.forEach { manager in
            firebase.createNotification(
                organizationId: organizationId,
                userId: manager.id,
                title: title,
                body: body,
                type: "QUOTATION_SUBMITTED",
                targetId: jobId
            ) { _ in }
        }
    }

    func createItem(organizationId: String, userId: String, name: String, category: String, quantity: Int, unitPrice: Double, sku: String?, imageData: Data?, isOnline: Bool, completion: @escaping (InventoryItem?) -> Void) {
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
        let itemId = UUID().uuidString
        let trimmedSku = sku?.trimmingCharacters(in: .whitespacesAndNewlines)

        func persistItem(imageUrl: String?) {
            let item = InventoryItem(
                id: itemId,
                organizationId: organizationId,
                name: trimmedName,
                category: trimmedCategory,
                quantity: max(0, quantity),
                unitPrice: max(0, unitPrice),
                sku: trimmedSku,
                imageUrl: imageUrl
            )

            self.localStorage.saveInventoryItems([item])
            self.items = self.localStorage.fetchInventoryItems(organizationId: organizationId)

            guard isOnline else {
                SyncManager.shared.enqueueCreateInventoryItem(item, organizationId: organizationId, userId: userId)
                completion(item)
                return
            }

            self.firebase.createInventoryItem(item) { result in
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

        guard let imageData = imageData else {
            persistItem(imageUrl: nil)
            return
        }

        guard isOnline else {
            errorMessage = "Photo upload is offline. Item saved without a photo."
            persistItem(imageUrl: nil)
            return
        }

        let fileName = "\(itemId)_\(Int(Date().timeIntervalSince1970)).jpg"
        firebase.uploadInventoryPhoto(data: imageData, fileName: fileName, itemId: itemId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let urlString):
                    persistItem(imageUrl: urlString)
                case .failure:
                    self.errorMessage = "Photo upload failed. Item saved without a photo."
                    persistItem(imageUrl: nil)
                }
            }
        }
    }

    func updateItem(_ item: InventoryItem, userId: String, name: String, category: String, quantity: Int, unitPrice: Double, sku: String?, imageUrl: String?, imageData: Data?, isOnline: Bool, completion: @escaping (InventoryItem?) -> Void) {
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
        let trimmedSku = sku?.trimmingCharacters(in: .whitespacesAndNewlines)

        func persistItem(updatedImageUrl: String?) {
            let updated = InventoryItem(
                id: item.id,
                organizationId: item.organizationId,
                name: trimmedName,
                category: trimmedCategory,
                quantity: max(0, quantity),
                unitPrice: max(0, unitPrice),
                sku: trimmedSku,
                imageUrl: updatedImageUrl
            )

            self.localStorage.saveInventoryItems([updated])
            self.items = self.localStorage.fetchInventoryItems(organizationId: item.organizationId)

            let fields: [String: Any] = [
                "name": updated.name,
                "category": updated.category,
                "quantity": updated.quantity,
                "unitPrice": updated.unitPrice,
                "sku": updated.sku as Any,
                "imageUrl": updated.imageUrl as Any
            ]

            guard isOnline else {
                SyncManager.shared.enqueueUpdateInventoryItem(itemId: updated.id, fields: fields, organizationId: updated.organizationId, userId: userId)
                completion(updated)
                return
            }

            self.firebase.updateInventoryItem(itemId: item.id, fields: fields) { result in
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

        guard let imageData = imageData else {
            persistItem(updatedImageUrl: imageUrl)
            return
        }

        guard isOnline else {
            errorMessage = "Photo upload is offline. Item saved without a new photo."
            persistItem(updatedImageUrl: imageUrl)
            return
        }

        let fileName = "\(item.id)_\(Int(Date().timeIntervalSince1970)).jpg"
        firebase.uploadInventoryPhoto(data: imageData, fileName: fileName, itemId: item.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let urlString):
                    persistItem(updatedImageUrl: urlString)
                case .failure:
                    self.errorMessage = "Photo upload failed. Item saved without a new photo."
                    persistItem(updatedImageUrl: imageUrl)
                }
            }
        }
    }

    func deleteItem(_ item: InventoryItem, userId: String, isOnline: Bool, completion: @escaping (Bool) -> Void) {
        localStorage.deleteInventoryItem(id: item.id)
        items = localStorage.fetchInventoryItems(organizationId: item.organizationId)

        guard isOnline else {
            SyncManager.shared.enqueueDeleteInventoryItem(itemId: item.id, organizationId: item.organizationId, userId: userId)
            completion(true)
            return
        }

        firebase.deleteInventoryItem(itemId: item.id) { result in
            DispatchQueue.main.async {
                if case .failure(let error) = result {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
}
