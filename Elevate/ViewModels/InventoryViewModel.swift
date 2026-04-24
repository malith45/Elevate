import Foundation
import Combine
import UIKit
import FirebaseFirestore

final class InventoryViewModel: ObservableObject {
    @Published var items: [InventoryItem] = []
    @Published var quantities: [String: Int] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let localStorage = LocalStorageService.shared
    private let firebase = FirebaseService.shared
    private var inventoryListener: ListenerRegistration?

    func loadItems(organizationId: String, isOnline: Bool) {
        isLoading = true
        // Show cached data immediately
        items = localStorage.fetchInventoryItems(organizationId: organizationId)

        guard isOnline else {
            isLoading = false
            return
        }

        // Attach a real-time listener — fires on any add/update/delete in Firebase
        inventoryListener?.remove()
        inventoryListener = firebase.listenToInventory(organizationId: organizationId) { [weak self] remoteItems in
            self?.handleRealtimeInventory(remoteItems, organizationId: organizationId)
        }
    }

    /// Syncs the real-time snapshot: upserts new/changed items and purges deleted ones.
    private func handleRealtimeInventory(_ remoteItems: [InventoryItem], organizationId: String) {
        let remoteIds = Set(remoteItems.map { $0.id })
        let localItems = localStorage.fetchInventoryItems(organizationId: organizationId)
        for localItem in localItems where !remoteIds.contains(localItem.id) {
            localStorage.deleteInventoryItem(id: localItem.id)
        }
        localStorage.saveInventoryItems(remoteItems)
        DispatchQueue.main.async {
            self.items = remoteItems
            self.isLoading = false
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
            
            // Critical Stock Alert
            if newQuantity < 5 {
                NotificationManager.shared.notifyManagers(
                    organizationId: organizationId,
                    type: .criticalInventory,
                    title: "Critical Stock Alert",
                    body: "Item '\(inventoryItem.name)' is running low (\(newQuantity) left).",
                    targetId: inventoryItem.id
                )
            }
        }

        if !updatedInventory.isEmpty {
            localStorage.saveInventoryItems(updatedInventory)
            self.items = localStorage.fetchInventoryItems(organizationId: organizationId)
        }
    }

    private func notifyManagersForQuotation(jobId: String, organizationId: String, userId: String) {
        let technicianName = localStorage.fetchUser(id: userId)?.displayName ?? "Technician"
        let jobTitle = localStorage.fetchJob(id: jobId)?.title ?? "Job"
        let title = "New Quotation Request"
        let body = "\(technicianName) submitted a quote for: \(jobTitle)"
        
        NotificationManager.shared.notifyManagers(
            organizationId: organizationId,
            type: .quoteSubmitted,
            title: title,
            body: body,
            targetId: jobId
        )
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

        // Convert to Base64 with compression instead of uploading to Storage
        if let base64String = ImageUtils.compressAndEncode(data: imageData) {
            persistItem(imageUrl: base64String)
        } else {
            self.errorMessage = "Failed to process image. Item saved without a photo."
            persistItem(imageUrl: nil)
        }
        completion(nil)
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

        if let base64String = ImageUtils.compressAndEncode(data: imageData) {
            persistItem(updatedImageUrl: base64String)
        } else {
            self.errorMessage = "Failed to update image. Item saved without a new photo."
            persistItem(updatedImageUrl: imageUrl)
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

    deinit {
        inventoryListener?.remove()
    }
}
