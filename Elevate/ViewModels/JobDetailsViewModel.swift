import Foundation
import Combine
import UIKit

final class JobDetailsViewModel: ObservableObject {
    @Published var job: Job?

    private let localStorage = LocalStorageService.shared
    private let firebase = FirebaseService.shared

    func load(jobId: String) {
        job = localStorage.fetchJob(id: jobId)
    }

    func updateStatus(jobId: String, status: String, user: User, isOnline: Bool) {
        guard let current = localStorage.fetchJob(id: jobId) else { return }

        let updatedAt = Date()
        let normalized = status.uppercased()
        let isOnHold = normalized == "HOLD"
        let holdReason = isOnHold ? (current.holdReason ?? "On hold") : nil
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
        let fileName = "job_\(jobId)_\(UUID().uuidString).jpg"
        if let localUrl = localStorage.saveImageData(data, fileName: fileName) {
            localStorage.appendJobPhotoUrl(jobId: jobId, url: localUrl)
            job = localStorage.fetchJob(id: jobId)

            if isOnline {
                firebase.uploadJobPhoto(data: data, fileName: fileName, jobId: jobId) { result in
                    if case .success(let remoteUrl) = result {
                        self.localStorage.replaceJobPhotoUrl(jobId: jobId, from: localUrl, to: remoteUrl)
                        DispatchQueue.main.async {
                            self.job = self.localStorage.fetchJob(id: jobId)
                        }
                    }
                }
            }
        }
    }
}
