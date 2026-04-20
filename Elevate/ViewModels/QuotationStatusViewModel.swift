import Foundation
import Combine
import FirebaseFirestore

final class QuotationStatusViewModel: ObservableObject {
    @Published var items: [QuotationItem] = []
    @Published var errorMessage: String?

    private let firebase = FirebaseService.shared
    private let localStorage = LocalStorageService.shared
    private let network = NetworkService.shared
    private var jobListener: ListenerRegistration?

    var approvedItems: [QuotationItem] {
        items.filter { $0.status.uppercased() == "APPROVED" }
    }

    var pendingItems: [QuotationItem] {
        items.filter { $0.status.uppercased() == "PENDING" }
    }

    var rejectedItems: [QuotationItem] {
        items.filter { $0.status.uppercased() == "REJECTED" }
    }

    var totalCost: Double {
        approvedItems.reduce(0) { $0 + (Double($1.quantity) * $1.unitPrice) }
    }

    func load(jobId: String) {
        if let cached = localStorage.fetchJob(id: jobId)?.quotationItems {
            items = cached
        }

        jobListener?.remove()
        jobListener = nil

        guard network.isOnline else { return }

        jobListener = firebase.listenToJob(jobId: jobId) { [weak self] job in
            guard let self = self, let job = job else { return }
            self.localStorage.saveJobs([job])
            DispatchQueue.main.async {
                self.items = job.quotationItems
            }
        }

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

    func removePendingItem(jobId: String, itemId: String, userId: String, organizationId: String) {
        guard let job = localStorage.fetchJob(id: jobId) else { return }
        guard let item = job.quotationItems.first(where: { $0.id == itemId }) else { return }
        guard item.status.uppercased() == "PENDING" else { return }

        let updatedItems = job.quotationItems.filter { $0.id != itemId }
        let approvedItems = updatedItems.filter { $0.status.uppercased() == "APPROVED" }
        let approvedCost = approvedItems.reduce(0) { $0 + (Double($1.quantity) * $1.unitPrice) }

        localStorage.updateJobQuotationItems(id: jobId, items: updatedItems, updatedAt: Date())
        items = updatedItems

        restoreInventory(item: item, organizationId: organizationId, userId: userId, isOnline: network.isOnline)

        guard network.isOnline else {
            SyncManager.shared.enqueueQuotationItemsUpdate(
                jobId: jobId,
                organizationId: organizationId,
                userId: userId,
                items: updatedItems,
                approvedCost: approvedCost
            )
            return
        }

        firebase.updateQuotationItems(jobId: jobId, items: updatedItems, approvedCost: approvedCost) { result in
            DispatchQueue.main.async {
                if case .failure(let error) = result {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func restoreInventory(item: QuotationItem, organizationId: String, userId: String, isOnline: Bool) {
        guard let inventoryItem = localStorage.fetchInventoryItem(id: item.id) else { return }
        let newQuantity = max(0, inventoryItem.quantity + item.quantity)
        localStorage.updateInventoryQuantity(itemId: inventoryItem.id, quantity: newQuantity)

        let fields: [String: Any] = ["quantity": newQuantity]
        if isOnline {
            firebase.updateInventoryItem(itemId: inventoryItem.id, fields: fields) { _ in }
        } else {
            SyncManager.shared.enqueueUpdateInventoryItem(itemId: inventoryItem.id, fields: fields, organizationId: organizationId, userId: userId)
        }
    }

    deinit {
        jobListener?.remove()
    }
}
