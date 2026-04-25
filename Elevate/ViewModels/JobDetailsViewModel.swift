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

        var updatedQuotationItems = current.quotationItems
        if normalized == "COMPLETED" || normalized == "CANCELLED" {
            updatedQuotationItems = current.quotationItems.map { item in
                if item.status.uppercased() == "PENDING" {
                    return QuotationItem(
                        id: item.id,
                        name: item.name,
                        unitPrice: item.unitPrice,
                        quantity: item.quantity,
                        status: "REJECTED"
                    )
                }
                return item
            }
        }

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
            quotationItems: updatedQuotationItems,
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
                // Notification Triggers
                if user.role.uppercased() == "TECHNICIAN" {
                    // Notify managers of technician status changes
                    let type: NotificationManager.NotificationType
                    let title: String
                    let body: String
                    
                    switch normalized {
                    case "STARTED":
                        type = .jobStarted
                        title = "Job Started"
                        body = "Technician \(user.displayName) has started working on: \(current.title)"
                    case "HOLD":
                        type = .jobHold
                        title = "Job On Hold"
                        body = "Technician \(user.displayName) put job on hold: \(current.title). Reason: \(holdReason ?? "N/A")"
                    case "COMPLETED":
                        type = .jobCompleted
                        title = "Job Completed"
                        body = "Technician \(user.displayName) has completed: \(current.title)"
                    default:
                        return
                    }
                    
                    NotificationManager.shared.notifyManagers(
                        organizationId: user.organizationId,
                        type: type,
                        title: title,
                        body: body,
                        targetId: jobId
                    )
                } else if user.role.uppercased() == "MANAGER" && normalized == "CANCELLED" {
                    // Notify technician of cancellation
                    NotificationManager.shared.sendNotification(
                        to: current.assignedUserId,
                        organizationId: user.organizationId,
                        type: .jobCancelled,
                        title: "Job Cancelled",
                        body: "Manager has cancelled job: \(current.title)",
                        targetId: jobId
                    )
                }
                
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

    func cancelJobAndCleanup(job: Job, user: User, isOnline: Bool, completion: @escaping (Bool) -> Void) {
        // 1. Restore Inventory for approved items
        let approvedItems = job.quotationItems.filter { $0.status.uppercased() == "APPROVED" }
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

        // 2. Reject all PENDING quotation items so they don't stay in limbo
        let updatedItems = job.quotationItems.map { item -> QuotationItem in
            if item.status.uppercased() == "PENDING" {
                return QuotationItem(
                    id: item.id,
                    name: item.name,
                    unitPrice: item.unitPrice,
                    quantity: item.quantity,
                    status: "REJECTED"
                )
            }
            return item
        }

        // 3. Update Job Status to CANCELLED and persist updated items
        let updatedJob = Job(
            id: job.id,
            organizationId: job.organizationId,
            title: job.title,
            location: job.location,
            siteLatitude: job.siteLatitude,
            siteLongitude: job.siteLongitude,
            scheduledAt: job.scheduledAt,
            status: "CANCELLED",
            priority: job.priority,
            isUrgent: job.isUrgent,
            isOnHold: job.isOnHold,
            holdReason: job.holdReason,
            cancelledAt: Date(),
            assignedUserId: job.assignedUserId,
            notes: job.notes,
            quotationItems: updatedItems,
            approvedCost: job.approvedCost,
            photoUrls: job.photoUrls,
            updatedAt: Date()
        )
        
        localStorage.saveJobs([updatedJob])
        self.job = updatedJob

        // Persist to Firebase
        let fields: [String: Any] = [
            "status": "CANCELLED",
            "cancelledAt": Date(),
            "updatedAt": Date(),
            "quotationItems": updatedItems.map { [
                "id": $0.id,
                "name": $0.name,
                "unitPrice": $0.unitPrice,
                "quantity": $0.quantity,
                "status": $0.status
            ] }
        ]

        if isOnline {
            firebase.updateJobFields(jobId: job.id, fields: fields) { _ in
                // Notify technician of cancellation
                NotificationManager.shared.sendNotification(
                    to: job.assignedUserId,
                    organizationId: user.organizationId,
                    type: .jobCancelled,
                    title: "Job Cancelled",
                    body: "Manager has cancelled job: \(job.title)",
                    targetId: job.id
                )
                DispatchQueue.main.async { completion(true) }
            }
        } else {
            SyncManager.shared.enqueueJobFieldsUpdate(
                jobId: job.id,
                fields: fields,
                organizationId: user.organizationId,
                userId: user.id
            )
            DispatchQueue.main.async { completion(true) }
        }
    }
}
