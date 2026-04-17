import Foundation
import Combine

final class JobsViewModel: ObservableObject {
    @Published var jobs: [Job] = []
    @Published var searchText = ""
    @Published var selectedFilter: JobFilter = .today
    @Published var errorMessage: String?

    private let localStorage = LocalStorageService.shared

    enum JobFilter: Int, CaseIterable {
        case today = 0
        case upcoming = 1
        case completed = 2
    }

    var filteredJobs: [Job] {
        let calendar = Calendar.current
        let filteredByDate: [Job] = jobs.filter { job in
            switch selectedFilter {
            case .today:
                return calendar.isDateInToday(job.scheduledAt) && job.status.uppercased() != "COMPLETED"
            case .upcoming:
                // Include all jobs not completed (past, today, future)
                // The view will handle sectioning them into "Past" and "Upcoming"
                return job.status.uppercased() != "COMPLETED"
            case .completed:
                return job.status.uppercased() == "COMPLETED"
            }
        }

        guard !searchText.isEmpty else { return filteredByDate }
        let query = searchText.lowercased()
        return filteredByDate.filter {
            $0.title.lowercased().contains(query) || $0.location.lowercased().contains(query)
        }
    }

    func loadJobs(organizationId: String, userId: String, isOnline: Bool) {
        jobs = localStorage.fetchJobs(organizationId: organizationId)

        if isOnline {
            SyncManager.shared.startSyncing(organizationId: organizationId, userId: userId) { [weak self] in
                let refreshed = self?.localStorage.fetchJobs(organizationId: organizationId) ?? []
                DispatchQueue.main.async {
                    self?.jobs = refreshed
                }
            }
        }
    }
}
