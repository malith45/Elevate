import Foundation
import Combine

struct WeeklyJobStat: Identifiable {
    let id = UUID()
    let label: String
    let total: Int
    let completed: Int
}

struct DailyEfficiencyStat: Identifiable {
    let id = UUID()
    let dayIndex: Int
    let value: Double
}

final class StatisticsViewModel: ObservableObject {
    @Published var jobs: [Job] = []
    @Published var technicians: [User] = []
    @Published var weeklyStats: [WeeklyJobStat] = []
    @Published var efficiencyStats: [DailyEfficiencyStat] = []
    @Published var completionRate: Double = 0
    @Published var onScheduleRate: Double = 0

    private let localStorage = LocalStorageService.shared

    func load(organizationId: String, userId: String, isOnline: Bool, technicianId: String? = nil) {
        jobs = filteredJobs(organizationId: organizationId, technicianId: technicianId)
        technicians = localStorage.fetchUsers(organizationId: organizationId)
            .filter { $0.role.uppercased() == "TECHNICIAN" }
        computeStats(from: jobs)

        guard isOnline else { return }
        SyncManager.shared.startSyncing(organizationId: organizationId, userId: userId) { [weak self] in
            guard let self = self else { return }
            let refreshed = self.filteredJobs(organizationId: organizationId, technicianId: technicianId)
            DispatchQueue.main.async(execute: DispatchWorkItem(block: {
                self.jobs = refreshed
                self.computeStats(from: refreshed)
                self.technicians = self.localStorage.fetchUsers(organizationId: organizationId)
                    .filter { $0.role.uppercased() == "TECHNICIAN" }
            }))
        }
    }

    private func filteredJobs(organizationId: String, technicianId: String?) -> [Job] {
        let all = localStorage.fetchJobs(organizationId: organizationId)
        guard let technicianId = technicianId, !technicianId.isEmpty else { return all }
        return all.filter { $0.assignedUserId == technicianId }
    }

    private func computeStats(from jobs: [Job]) {
        weeklyStats = makeWeeklyStats(from: jobs)
        efficiencyStats = makeEfficiencyStats(from: jobs)

        let total = jobs.count
        let completed = jobs.filter { $0.status.uppercased() == "COMPLETED" }.count
        completionRate = total == 0 ? 0 : Double(completed) / Double(total)

        let scheduled = jobs.filter { $0.status.uppercased() != "CANCELLED" }.count
        onScheduleRate = scheduled == 0 ? 0 : Double(completed) / Double(scheduled)
    }

    private func makeWeeklyStats(from jobs: [Job]) -> [WeeklyJobStat] {
        let calendar = Calendar.current
        let today = Date()
        var stats: [WeeklyJobStat] = []

        for offset in (0..<4).reversed() {
            let start = calendar.date(byAdding: .day, value: -(offset * 7), to: startOfWeek(for: today)) ?? today
            let end = calendar.date(byAdding: .day, value: 7, to: start) ?? today
            let weekJobs = jobs.filter { $0.scheduledAt >= start && $0.scheduledAt < end }
            let completed = weekJobs.filter { $0.status.uppercased() == "COMPLETED" }.count
            let label = "WEEK \(4 - offset)"
            stats.append(WeeklyJobStat(label: label, total: weekJobs.count, completed: completed))
        }

        return stats
    }

    private func makeEfficiencyStats(from jobs: [Job]) -> [DailyEfficiencyStat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var stats: [DailyEfficiencyStat] = []

        for dayOffset in (0..<6).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let dayJobs = jobs.filter { calendar.isDate($0.scheduledAt, inSameDayAs: day) }
            let completed = dayJobs.filter { $0.status.uppercased() == "COMPLETED" }.count
            let rate = dayJobs.isEmpty ? 0.5 : Double(completed) / Double(dayJobs.count)
            let value = min(100, max(40, rate * 100))
            stats.append(DailyEfficiencyStat(dayIndex: 6 - dayOffset, value: value))
        }

        return stats
    }

    private func startOfWeek(for date: Date) -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }
}
