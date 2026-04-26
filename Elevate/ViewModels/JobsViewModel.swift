import Foundation
import Combine
import FirebaseFirestore


final class JobsViewModel: ObservableObject {
    @Published var jobs: [Job] = []
    @Published var searchText = ""
    @Published var selectedFilter: JobFilter = .today
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let localStorage = LocalStorageService.shared
    private let firebase = FirebaseService.shared
    private var jobsListener: ListenerRegistration?

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
                let isToday = calendar.isDateInToday(job.scheduledAt)
                let isOverdue = job.scheduledAt < Date()
                return (isToday || isOverdue)
                    && status != "COMPLETED"
                    && status != "CANCELLED"
            case .upcoming:
                let startOfToday = calendar.startOfDay(for: Date())
                let isFuture = job.scheduledAt >= calendar.date(byAdding: .day, value: 1, to: startOfToday)!
                return isFuture && status != "COMPLETED" && status != "CANCELLED"
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

        // Immediately show cached data while the network loads
        jobs = localStorage.fetchJobs(organizationId: organizationId, userId: assignedUserId)

        if isOnline {
            // Attach a real-time Firestore listener so any add/update/delete
            // in Firebase is reflected in the UI immediately.
            jobsListener?.remove()
            if role == "TECHNICIAN" {
                jobsListener = firebase.listenToJobs(
                    organizationId: organizationId,
                    assignedUserId: userId
                ) { [weak self] remoteJobs in
                    self?.handleRealtimeJobs(
                        remoteJobs,
                        organizationId: organizationId,
                        assignedUserId: assignedUserId
                    )
                }
            } else {
                jobsListener = firebase.listenToOrganizationJobs(
                    organizationId: organizationId
                ) { [weak self] remoteJobs in
                    self?.handleRealtimeJobs(
                        remoteJobs,
                        organizationId: organizationId,
                        assignedUserId: nil
                    )
                }
            }

            // Also run the full sync (handles pending offline actions, photos, etc.)
            SyncManager.shared.startSyncing(
                organizationId: organizationId,
                userId: userId,
                role: role
            ) { [weak self] in
                DispatchQueue.main.async { self?.isLoading = false }
            }
        } else {
            isLoading = false
        }
    }

    /// Applies the snapshot from Firestore: updates the published list AND syncs the local cache.
    private func handleRealtimeJobs(_ remoteJobs: [Job], organizationId: String, assignedUserId: String?) {
        // Purge locally deleted jobs
        let remoteIds = Set(remoteJobs.map { $0.id })
        let localJobs = localStorage.fetchJobs(organizationId: organizationId, userId: assignedUserId)
        for localJob in localJobs where !remoteIds.contains(localJob.id) {
            localStorage.deleteJob(id: localJob.id)
        }
        // Upsert the latest data
        localStorage.saveJobs(remoteJobs)

        DispatchQueue.main.async {
            self.jobs = remoteJobs
            self.isLoading = false
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
        jobsListener?.remove()
        NotificationCenter.default.removeObserver(self)
    }
}
