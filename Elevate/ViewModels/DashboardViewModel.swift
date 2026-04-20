import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var jobs: [Job] = []
    @Published var totalJobsToday = 0
    @Published var urgentJobsToday = 0

    private let localStorage = LocalStorageService.shared

    func loadJobs(organizationId: String, userId: String, isOnline: Bool, completion: (() -> Void)? = nil) {
        let localJobs = localStorage.fetchJobs(organizationId: organizationId)
        applyJobs(localJobs)

        guard isOnline else {
            completion?()
            return
        }

        SyncManager.shared.startSyncing(organizationId: organizationId, userId: userId) { [weak self] in
            Task { @MainActor in
                let refreshed = self?.localStorage.fetchJobs(organizationId: organizationId) ?? []
                self?.applyJobs(refreshed)
                completion?()
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
