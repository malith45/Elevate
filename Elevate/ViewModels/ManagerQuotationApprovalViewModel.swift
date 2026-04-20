import Foundation
import Combine

final class ManagerQuotationApprovalViewModel: ObservableObject {
    @Published var job: Job?
    @Published var items: [QuotationItem] = []
    @Published var errorMessage: String?

    private var actorUserId: String?

    private let localStorage = LocalStorageService.shared
    private let firebase = FirebaseService.shared
    private let network = NetworkService.shared

    func load(jobId: String, actorUserId: String) {
        self.actorUserId = actorUserId
        job = localStorage.fetchJob(id: jobId)
        items = job?.quotationItems ?? []
    }

    func approveAll() {
        let updated = items.map { item in
            QuotationItem(
                id: item.id,
                name: item.name,
                unitPrice: item.unitPrice,
                quantity: item.quantity,
                status: "APPROVED"
            )
        }
        persist(items: updated)
    }

    func updateStatus(itemId: String, status: String) {
        let updated = items.map { item in
            guard item.id == itemId else { return item }
            return QuotationItem(
                id: item.id,
                name: item.name,
                unitPrice: item.unitPrice,
                quantity: item.quantity,
                status: status
            )
        }
        persist(items: updated)
    }

    private func persist(items: [QuotationItem]) {
        guard let job = job else { return }
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

        localStorage.saveJobs([updatedJob])
        self.job = updatedJob
        self.items = items

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
                }
            }))
        }
    }
}
