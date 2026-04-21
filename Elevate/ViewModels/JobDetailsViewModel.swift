import Combine
import UIKit
import FirebaseFirestore
import CoreLocation

final class JobDetailsViewModel: ObservableObject {
    @Published var job: Job?
    @Published var assignedTechnician: User?
    @Published var technicianLocation: CLLocationCoordinate2D?

    private var locationListener: ListenerRegistration?

    private let localStorage = LocalStorageService.shared
    private let firebase = FirebaseService.shared

    func load(jobId: String) {
        job = localStorage.fetchJob(id: jobId)
        if let assignedId = job?.assignedUserId {
            assignedTechnician = localStorage.fetchUser(id: assignedId)
            
            // Start listening to technician location
            locationListener?.remove()
            locationListener = FirebaseService.shared.listenToUserLocation(userId: assignedId) { [weak self] coord in
                DispatchQueue.main.async {
                    self?.technicianLocation = coord
                }
            }
        }
    }

    deinit {
        locationListener?.remove()
    }

    func updateStatus(jobId: String, status: String, user: User, isOnline: Bool, holdReasonOverride: String? = nil) {
        guard let current = localStorage.fetchJob(id: jobId) else { return }

        let updatedAt = Date()
        let normalized = status.uppercased()
        let isOnHold = normalized == "HOLD"
        let trimmedHoldReason = holdReasonOverride?.trimmingCharacters(in: .whitespacesAndNewlines)
        let holdReason = isOnHold ? (trimmedHoldReason?.isEmpty == false ? trimmedHoldReason : (current.holdReason ?? "On hold")) : nil
        let cancelledAt = normalized == "CANCELLED" ? updatedAt : current.cancelledAt

        let updatedJob = Job(
            id: current.id,
            organizationId: current.organizationId,
            title: current.title,
            location: current.location,
            siteLatitude: current.siteLatitude,
            siteLongitude: current.siteLongitude,
            scheduledAt: current.scheduledAt,
            status: status,
            priority: current.priority,
            isUrgent: current.isUrgent,
            isOnHold: isOnHold,
            holdReason: holdReason,
            cancelledAt: cancelledAt,
            assignedUserId: current.assignedUserId,
            notes: current.notes,
            quotationItems: current.quotationItems,
            approvedCost: current.approvedCost,
            photoUrls: current.photoUrls,
            updatedAt: updatedAt
        )

        localStorage.saveJobs([updatedJob])
        job = updatedJob

        if normalized == "COMPLETED" {
            DispatchQueue.main.async {
                HapticManager.shared.playNotification(type: .success)
            }
        }

        var fields: [String: Any] = [
            "status": status,
            "isOnHold": isOnHold
        ]
        if let holdReason = holdReason {
            fields["holdReason"] = holdReason
        }
        if let cancelledAt = cancelledAt {
            fields["cancelledAt"] = cancelledAt
        }

        if isOnline {
            firebase.updateJobFields(jobId: jobId, fields: fields) { _ in }
        } else {
            SyncManager.shared.enqueueJobFieldsUpdate(
                jobId: jobId,
                fields: fields,
                organizationId: user.organizationId,
                userId: user.id
            )
        }
    }

    func addPhoto(jobId: String, data: Data, isOnline: Bool) {
        guard let base64String = ImageUtils.compressAndEncode(data: data) else { return }
        
        localStorage.appendJobPhotoUrl(jobId: jobId, url: base64String)
        job = localStorage.fetchJob(id: jobId)

        if isOnline {
            firebase.updateJobFields(jobId: jobId, fields: [
                "photoUrls": FieldValue.arrayUnion([base64String])
            ]) { _ in }
        }
    }

    func deleteJobAndCleanup(job: Job, user: User, isOnline: Bool, completion: @escaping (Bool) -> Void) {
        // 1. Restore Inventory for approved items
        let approvedItems = job.quotationItems.filter { $0.status == "APPROVED" }
        for item in approvedItems {
            if let inventoryItem = localStorage.fetchInventoryItem(id: item.id) {
                let newQuantity = inventoryItem.quantity + item.quantity
                localStorage.updateInventoryQuantity(itemId: item.id, quantity: newQuantity)
                
                if isOnline {
                    firebase.updateInventoryItem(itemId: item.id, fields: ["quantity": newQuantity]) { _ in }
                } else {
                    SyncManager.shared.enqueueUpdateInventoryItem(
                        itemId: item.id,
                        fields: ["quantity": newQuantity],
                        organizationId: user.organizationId,
                        userId: user.id
                    )
                }
            }
        }

        // 2. Delete Issue Reports
        localStorage.deleteIssueReportsForJob(jobId: job.id)
        if isOnline {
            firebase.deleteIssueReportsForJob(jobId: job.id) { _ in }
        }

        // 3. Delete Job
        localStorage.deleteJob(id: job.id)
        
        if isOnline {
            firebase.deleteJob(jobId: job.id) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        HapticManager.shared.playNotification(type: .success)
                        completion(true)
                    case .failure:
                        completion(false)
                    }
                }
            }
        } else {
            // If offline, we'd need a deleteJob action in SyncManager, 
            // but for now we'll assume success locally as per request.
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
}
