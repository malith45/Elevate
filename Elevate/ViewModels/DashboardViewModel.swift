import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var jobs: [Job] = []
    @Published var totalJobsToday = 0
    @Published var urgentJobsToday = 0
    @Published var isLoading = false

    private let localStorage = LocalStorageService.shared

    func loadJobs(organizationId: String, userId: String, role: String, isOnline: Bool, completion: (() -> Void)? = nil) {
        let assignedUserId = (role == "TECHNICIAN") ? userId : nil
        let localJobs = localStorage.fetchJobs(organizationId: organizationId, userId: assignedUserId)
        applyJobs(localJobs)

        guard isOnline else {
            completion?()
            return
        }

        isLoading = true
        SyncManager.shared.startSyncing(organizationId: organizationId, userId: userId, role: role) { [weak self] in
            Task { @MainActor in
                let refreshed = self?.localStorage.fetchJobs(organizationId: organizationId, userId: assignedUserId) ?? []
                self?.applyJobs(refreshed)
                self?.isLoading = false
                completion?()
            }
        }
    }

    private func applyJobs(_ jobs: [Job]) {
        self.jobs = jobs
        let calendar = Calendar.current
        let todayJobs = jobs.filter { calendar.isDateInToday($0.scheduledAt) }
        totalJobsToday = todayJobs.count
        
        // Count all pending urgent jobs (not just today)
        urgentJobsToday = jobs.filter { 
            let priority = $0.priority.uppercased()
            let status = $0.status.uppercased()
            return (priority == "HIGH" || priority == "URGENT") && 
                   (status != "COMPLETED" && status != "CANCELLED")
        }.count
    }
}
