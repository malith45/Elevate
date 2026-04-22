import Combine
import UIKit
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

final class JobDetailsViewModel: ObservableObject {
    @Published var job: Job?
    @Published var assignedTechnician: User?
    @Published var technicianLocation: CLLocationCoordinate2D?

    private var locationListener: ListenerRegistration?
    private var jobListener: ListenerRegistration?

    private let localStorage = LocalStorageService.shared
    private let firebase = FirebaseService.shared

    func load(jobId: String) {
        job = localStorage.fetchJob(id: jobId)
        if let assignedId = job?.assignedUserId {
            assignedTechnician = localStorage.fetchUser(id: assignedId)

            // Listen to technician location
            locationListener?.remove()
            locationListener = FirebaseService.shared.listenToUserLocation(userId: assignedId) { [weak self] coord in
                DispatchQueue.main.async {
                    self?.technicianLocation = coord
                }
            }
        }

        // Attach a real-time Firestore listener for the job document.
        // This keeps the details view live even if the manager changes the status remotely.
        jobListener?.remove()
        jobListener = firebase.listenToJob(jobId: jobId) { [weak self] updatedJob in
            guard let self, let updatedJob else { return }
            DispatchQueue.main.async {
                self.localStorage.saveJobs([updatedJob])
                self.job = updatedJob
            }
        }
    }

    deinit {
        locationListener?.remove()
        jobListener?.remove()
    }

    func updateStatus(jobId: String, status: String, user: User, isOnline: Bool, holdReasonOverride: String? = nil, completion: (() -> Void)? = nil) {
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

        // Notify list views to refresh from cache
        NotificationCenter.default.post(name: .jobStatusDidChange, object: jobId)

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
            firebase.updateJobFields(jobId: jobId, fields: fields) { _ in
                DispatchQueue.main.async { completion?() }
            }
        } else {
            SyncManager.shared.enqueueJobFieldsUpdate(
                jobId: jobId,
                fields: fields,
                organizationId: user.organizationId,
                userId: user.id
            )
            DispatchQueue.main.async { completion?() }
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

    func removePhoto(jobId: String, url: String, isOnline: Bool) {
        localStorage.removeJobPhotoUrl(jobId: jobId, url: url)
        job = localStorage.fetchJob(id: jobId)

        if isOnline {
            firebase.updateJobFields(jobId: jobId, fields: [
                "photoUrls": FieldValue.arrayRemove([url])
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
            SyncManager.shared.enqueueDeleteJob(jobId: job.id, organizationId: user.organizationId, userId: user.id)
            DispatchQueue.main.async {
                HapticManager.shared.playNotification(type: .success)
                completion(true)
            }
        }
    }
}
