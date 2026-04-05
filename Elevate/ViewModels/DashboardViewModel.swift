import Foundation
import Combine

final class DashboardViewModel: ObservableObject {
    @Published var jobs: [Job] = []
    @Published var totalJobsToday = 0
    @Published var urgentJobsToday = 0

    private let localStorage = LocalStorageService.shared

    func loadJobs(organizationId: String, userId: String, isOnline: Bool) {
        let localJobs = localStorage.fetchJobs(organizationId: organizationId)
        applyJobs(localJobs)

        if isOnline {
            SyncManager.shared.startSyncing(organizationId: organizationId, userId: userId) { [weak self] in
                let refreshed = self?.localStorage.fetchJobs(organizationId: organizationId) ?? []
                DispatchQueue.main.async {
                    self?.applyJobs(refreshed)
                }
            }
        }
    }

    private func applyJobs(_ jobs: [Job]) {
        self.jobs = jobs
        let calendar = Calendar.current
        let todayJobs = jobs.filter { calendar.isDateInToday($0.scheduledAt) }
        totalJobsToday = todayJobs.count
        urgentJobsToday = todayJobs.filter { $0.priority.uppercased() == "HIGH" || $0.priority.uppercased() == "URGENT" }.count
    }
}
