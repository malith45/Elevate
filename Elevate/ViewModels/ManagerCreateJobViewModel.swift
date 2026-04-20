import Foundation
import Combine
import UIKit

final class ManagerCreateJobViewModel: ObservableObject {
    @Published var technicians: [User] = []
    @Published var errorMessage: String?
    @Published var isSaving = false

    private let localStorage = LocalStorageService.shared
    private let firebase = FirebaseService.shared

    func loadTechnicians(organizationId: String, isOnline: Bool) {
        technicians = localStorage.fetchUsers(organizationId: organizationId).filter { $0.role.uppercased() == "TECHNICIAN" }

        guard isOnline else { return }
        firebase.fetchUsers(organizationId: organizationId) { result in
            DispatchQueue.main.async(execute: DispatchWorkItem(block: {
                switch result {
                case .success(let users):
                    self.localStorage.saveUsers(users)
                    self.technicians = users.filter { $0.role.uppercased() == "TECHNICIAN" }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }))
        }
    }

    func createJob(organizationId: String, userId: String, assignedUserId: String, title: String, location: String, scheduledAt: Date, notes: String?, isUrgent: Bool, siteLatitude: Double?, siteLongitude: Double?, isOnline: Bool, completion: @escaping (Job?) -> Void) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Job title is required."
            completion(nil)
            return
        }
        guard !trimmedLocation.isEmpty else {
            errorMessage = "Location is required."
            completion(nil)
            return
        }
        guard !assignedUserId.isEmpty else {
            errorMessage = "Select a technician."
            completion(nil)
            return
        }

        isSaving = true
        let job = Job(
            id: UUID().uuidString,
            organizationId: organizationId,
            title: trimmedTitle,
            location: trimmedLocation,
            siteLatitude: siteLatitude,
            siteLongitude: siteLongitude,
            scheduledAt: scheduledAt,
            status: "SCHEDULED",
            priority: isUrgent ? "HIGH" : "NORMAL",
            isUrgent: isUrgent,
            isOnHold: false,
            holdReason: nil,
            cancelledAt: nil,
            assignedUserId: assignedUserId,
            notes: notes?.trimmingCharacters(in: .whitespacesAndNewlines),
            quotationItems: [],
            approvedCost: nil,
            photoUrls: [],
            updatedAt: Date()
        )

        localStorage.saveJobs([job])
        
        DispatchQueue.main.async {
            HapticManager.shared.playNotification(type: .success)
        }

        guard isOnline else {
            SyncManager.shared.enqueueCreateJob(job, organizationId: organizationId, userId: userId)
            isSaving = false
            completion(job)
            return
        }

        firebase.createJob(job) { result in
            DispatchQueue.main.async(execute: DispatchWorkItem(block: {
                self.isSaving = false
                switch result {
                case .success:
                    completion(job)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(nil)
                }
            }))
        }
    }
}
