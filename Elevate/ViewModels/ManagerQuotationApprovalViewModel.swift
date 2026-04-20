import Foundation
import Combine
import FirebaseFirestore

final class ManagerQuotationApprovalViewModel: ObservableObject {
    @Published var job: Job?
    @Published var items: [QuotationItem] = []
    @Published var jobs: [Job] = []
    @Published var errorMessage: String?

    private var actorUserId: String?
    private var currentJobId: String?
    private var jobsListener: ListenerRegistration?

    private let localStorage = LocalStorageService.shared
    private let firebase = FirebaseService.shared
    private let network = NetworkService.shared

    func load(jobId: String?, organizationId: String, actorUserId: String) {
        self.actorUserId = actorUserId
        self.currentJobId = jobId
        loadLocal(organizationId: organizationId)

        jobsListener?.remove()
        jobsListener = nil

        guard network.isOnline else { return }

        if let jobId = jobId {
            jobsListener = firebase.listenToJob(jobId: jobId) { [weak self] job in
                guard let self = self, let job = job else { return }
                self.localStorage.saveJobs([job])
                DispatchQueue.main.async {
                    self.job = job
                    self.items = job.quotationItems
                    self.jobs = [job]
                }
            }
        } else {
            jobsListener = firebase.listenToOrganizationJobs(organizationId: organizationId) { [weak self] jobs in
                guard let self = self else { return }
                self.localStorage.saveJobs(jobs)
                DispatchQueue.main.async {
                    self.jobs = self.filteredJobs(jobs)
                }
            }
        }
    }

    func approveAll(jobId: String? = nil) {
        guard let job = jobFor(id: jobId) else { return }
        let updated = job.quotationItems.map { item in
            QuotationItem(
                id: item.id,
                name: item.name,
                unitPrice: item.unitPrice,
                quantity: item.quantity,
                status: "APPROVED"
            )
        }
        persist(job: job, items: updated, oldItems: job.quotationItems, notifyMode: .bulkApproval)
    }

    func updateStatus(jobId: String, itemId: String, status: String) {
        guard let job = jobFor(id: jobId) else { return }
        let updated = job.quotationItems.map { item in
            guard item.id == itemId else { return item }
            return QuotationItem(
                id: item.id,
                name: item.name,
                unitPrice: item.unitPrice,
                quantity: item.quantity,
                status: status
            )
        }
        let itemName = job.quotationItems.first(where: { $0.id == itemId })?.name ?? "Item"
        persist(job: job, items: updated, oldItems: job.quotationItems, notifyMode: .singleItem(name: itemName, status: status))
    }

    private func loadLocal(organizationId: String) {
        if let jobId = currentJobId {
            job = localStorage.fetchJob(id: jobId)
            items = job?.quotationItems ?? []
            jobs = job.map { [$0] } ?? []
        } else {
            job = nil
            items = []
            jobs = filteredJobs(localStorage.fetchJobs(organizationId: organizationId))
        }
    }

    private func filteredJobs(_ jobs: [Job]) -> [Job] {
        jobs.filter { !$0.quotationItems.isEmpty }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    private func jobFor(id: String?) -> Job? {
        if let id = id ?? currentJobId {
            return localStorage.fetchJob(id: id)
        }
        return nil
    }

    private enum NotifyMode {
        case singleItem(name: String, status: String)
        case bulkApproval
    }

    private func persist(job: Job, items: [QuotationItem], oldItems: [QuotationItem], notifyMode: NotifyMode) {
        let approvedItems = items.filter { $0.status.uppercased() == "APPROVED" }
        let approvedCost = approvedItems.reduce(0) { $0 + (Double($1.quantity) * $1.unitPrice) }

        let updatedJob = Job(
            id: job.id,
            organizationId: job.organizationId,
            title: job.title,
            location: job.location,
            siteLatitude: job.siteLatitude,
            siteLongitude: job.siteLongitude,
            scheduledAt: job.scheduledAt,
            status: job.status,
            priority: job.priority,
            isUrgent: job.isUrgent,
            isOnHold: job.isOnHold,
            holdReason: job.holdReason,
            cancelledAt: job.cancelledAt,
            assignedUserId: job.assignedUserId,
            notes: job.notes,
            quotationItems: items,
            approvedCost: approvedCost,
            photoUrls: job.photoUrls,
            updatedAt: Date()
        )

        applyInventoryAdjustments(oldItems: oldItems, newItems: items, organizationId: job.organizationId)

        localStorage.saveJobs([updatedJob])
        self.job = updatedJob
        self.items = items
        if currentJobId == nil {
            let refreshed = filteredJobs(localStorage.fetchJobs(organizationId: job.organizationId))
            self.jobs = refreshed
        }

        guard network.isOnline else {
            if let actorUserId = actorUserId {
                SyncManager.shared.enqueueQuotationItemsUpdate(
                    jobId: job.id,
                    organizationId: job.organizationId,
                    userId: actorUserId,
                    items: items,
                    approvedCost: approvedCost
                )
            }
            errorMessage = "Offline. Changes will sync when online."
            return
        }

        firebase.updateQuotationItems(jobId: job.id, items: items, approvedCost: approvedCost) { result in
            DispatchQueue.main.async(execute: DispatchWorkItem(block: {
                if case .failure(let error) = result {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.sendNotification(for: job, mode: notifyMode)
                }
            }))
        }
    }

    private func applyInventoryAdjustments(oldItems: [QuotationItem], newItems: [QuotationItem], organizationId: String) {
        let oldMap = Dictionary(uniqueKeysWithValues: oldItems.map { ($0.id, $0) })
        var updatedInventory: [InventoryItem] = []

        newItems.forEach { newItem in
            guard let oldItem = oldMap[newItem.id] else { return }
            let oldStatus = oldItem.status.uppercased()
            let newStatus = newItem.status.uppercased()

            let shouldRestore = oldStatus != "REJECTED" && newStatus == "REJECTED"
            let shouldReduce = oldStatus == "REJECTED" && newStatus != "REJECTED"
            guard shouldRestore || shouldReduce else { return }

            guard let inventoryItem = localStorage.fetchInventoryItem(id: newItem.id) else { return }
            let delta = shouldRestore ? newItem.quantity : -newItem.quantity
            let newQuantity = max(0, inventoryItem.quantity + delta)
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
            if network.isOnline {
                firebase.updateInventoryItem(itemId: inventoryItem.id, fields: fields) { _ in }
            } else if let actorUserId = actorUserId {
                SyncManager.shared.enqueueUpdateInventoryItem(itemId: inventoryItem.id, fields: fields, organizationId: organizationId, userId: actorUserId)
            }
        }

        if !updatedInventory.isEmpty {
            localStorage.saveInventoryItems(updatedInventory)
        }
    }

    private func sendNotification(for job: Job, mode: NotifyMode) {
        let jobTitle = job.title

        switch mode {
        case .bulkApproval:
            firebase.createNotification(
                organizationId: job.organizationId,
                userId: job.assignedUserId,
                title: "Quotation approved",
                body: "Your quotation for \(jobTitle) was approved.",
                type: "QUOTATION_APPROVED",
                targetId: job.id
            ) { _ in }
        case .singleItem(let name, let status):
            let normalized = status.uppercased()
            if normalized == "APPROVED" {
                firebase.createNotification(
                    organizationId: job.organizationId,
                    userId: job.assignedUserId,
                    title: "Item approved",
                    body: "\(name) approved for \(jobTitle).",
                    type: "QUOTATION_APPROVED",
                    targetId: job.id
                ) { _ in }
            } else if normalized == "REJECTED" {
                firebase.createNotification(
                    organizationId: job.organizationId,
                    userId: job.assignedUserId,
                    title: "Item rejected",
                    body: "\(name) rejected for \(jobTitle).",
                    type: "QUOTATION_REJECTED",
                    targetId: job.id
                ) { _ in }
            }
        }
    }

    deinit {
        jobsListener?.remove()
    }
}
