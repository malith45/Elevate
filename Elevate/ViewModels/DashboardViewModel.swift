import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var jobs: [Job] = []
    @Published var totalJobsToday = 0
    @Published var urgentJobsToday = 0
    @Published var isLoading = false

    private let localStorage = LocalStorageService.shared
    private let firebase = FirebaseService.shared
    private var jobsListener: ListenerRegistration?

    func loadJobs(organizationId: String, userId: String, role: String, isOnline: Bool, completion: (() -> Void)? = nil) {
        let assignedUserId = (role == "TECHNICIAN") ? userId : nil

        // Show cached data immediately
        let localJobs = localStorage.fetchJobs(organizationId: organizationId, userId: assignedUserId)
        applyJobs(localJobs)

        guard isOnline else {
            completion?()
            return
        }

        isLoading = true

        // Attach a real-time listener so the dashboard counts update while the tab is open
        jobsListener?.remove()
        if role == "TECHNICIAN" {
            jobsListener = firebase.listenToJobs(
                organizationId: organizationId,
                assignedUserId: userId
            ) { [weak self] remoteJobs in
                Task { @MainActor in
                    self?.handleRealtimeJobs(remoteJobs, organizationId: organizationId, assignedUserId: assignedUserId)
                }
            }
        } else {
            jobsListener = firebase.listenToOrganizationJobs(
                organizationId: organizationId
            ) { [weak self] remoteJobs in
                Task { @MainActor in
                    self?.handleRealtimeJobs(remoteJobs, organizationId: organizationId, assignedUserId: nil)
                }
            }
        }

        // Also run the full sync to flush pending offline actions
        SyncManager.shared.startSyncing(organizationId: organizationId, userId: userId, role: role) { [weak self] in
            Task { @MainActor in
                self?.isLoading = false
                completion?()
            }
        }
    }

    private func handleRealtimeJobs(_ remoteJobs: [Job], organizationId: String, assignedUserId: String?) {
        // Purge deleted jobs from local cache
        let remoteIds = Set(remoteJobs.map { $0.id })
        let localJobs = localStorage.fetchJobs(organizationId: organizationId, userId: assignedUserId)
        for localJob in localJobs where !remoteIds.contains(localJob.id) {
            localStorage.deleteJob(id: localJob.id)
        }
        localStorage.saveJobs(remoteJobs)
        applyJobs(remoteJobs)
        isLoading = false
    }

    private func applyJobs(_ jobs: [Job]) {
        self.jobs = jobs
        let calendar = Calendar.current
        let todayJobs = jobs.filter { 
            calendar.isDateInToday($0.scheduledAt) &&
            $0.status.uppercased() != "COMPLETED" &&
            $0.status.uppercased() != "CANCELLED"
        }
        totalJobsToday = todayJobs.count

        // Count all pending urgent jobs (not just today)
        urgentJobsToday = jobs.filter {
            let priority = $0.priority.uppercased()
            let status = $0.status.uppercased()
            return (priority == "HIGH" || priority == "URGENT") &&
                   (status != "COMPLETED" && status != "CANCELLED")
        }.count
    }

    deinit {
        jobsListener?.remove()
    }
}
