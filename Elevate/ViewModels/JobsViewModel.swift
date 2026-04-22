import Foundation
import Combine

extension Notification.Name {
    static let jobStatusDidChange = Notification.Name("jobStatusDidChange")
}

final class JobsViewModel: ObservableObject {
    @Published var jobs: [Job] = []
    @Published var searchText = ""
    @Published var selectedFilter: JobFilter = .today
    @Published var isLoading = false
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
            let status = job.status.uppercased()
            switch selectedFilter {
            case .today:
                return calendar.isDateInToday(job.scheduledAt)
                    && status != "COMPLETED"
                    && status != "CANCELLED"
            case .upcoming:
                // Show all non-terminal active jobs; view handles Past/Upcoming sections
                return status != "COMPLETED" && status != "CANCELLED"
            case .completed:
                return status == "COMPLETED" || status == "CANCELLED"
            }
        }

        guard !searchText.isEmpty else { return filteredByDate }
        let query = searchText.lowercased()
        return filteredByDate.filter {
            $0.title.lowercased().contains(query) || $0.location.lowercased().contains(query)
        }
    }

    func loadJobs(organizationId: String, userId: String, role: String, isOnline: Bool) {
        isLoading = true
        let assignedUserId = (role == "TECHNICIAN") ? userId : nil
        jobs = localStorage.fetchJobs(organizationId: organizationId, userId: assignedUserId)
        
        if isOnline {
            SyncManager.shared.startSyncing(organizationId: organizationId, userId: userId, role: role) { [weak self] in
                let refreshed = self?.localStorage.fetchJobs(organizationId: organizationId, userId: assignedUserId) ?? []
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.jobs = refreshed
                }
            }
        } else {
            isLoading = false
        }
    }

    // Called by NotificationCenter when a status update fires from JobDetailsViewModel.
    private func reloadFromCache(organizationId: String, userId: String, role: String) {
        let assignedUserId = (role == "TECHNICIAN") ? userId : nil
        let refreshed = localStorage.fetchJobs(organizationId: organizationId, userId: assignedUserId)
        DispatchQueue.main.async {
            self.jobs = refreshed
        }
    }

    /// Call once from the owning View's onAppear to wire up live refresh.
    func startObservingStatusChanges(organizationId: String, userId: String, role: String) {
        NotificationCenter.default.addObserver(
            forName: .jobStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadFromCache(organizationId: organizationId, userId: userId, role: role)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
