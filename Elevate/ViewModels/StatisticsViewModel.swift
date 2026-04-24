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

enum TimeFilter: String, CaseIterable {
    case sevenDays = "Last 7 Days"
    case month = "Last Month"
    case year = "Last Year"
}

struct TechnicianJobCount: Identifiable {
    let id: String
    let name: String
    let assigned: Int
    let completed: Int
}

final class StatisticsViewModel: ObservableObject {
    @Published var selectedTimeFilter: TimeFilter = .month
    @Published var jobs: [Job] = []
    @Published var technicians: [User] = []
    @Published var weeklyStats: [WeeklyJobStat] = []
    @Published var efficiencyStats: [DailyEfficiencyStat] = []
    @Published var completionRate: Double = 0
    @Published var onScheduleRate: Double = 0
    @Published var comparisonLabel: String = "Vs. Team Average"
    @Published var comparisonDelta: Double = 0
    @Published var comparisonIsPositive: Bool = true
    
    // Status Counts for Top KPIs
    @Published var pendingCount: Int = 0
    @Published var startedCount: Int = 0
    @Published var onHoldCount: Int = 0
    @Published var cancelledCount: Int = 0
    @Published var completedCount: Int = 0
    
    // Technician Performance for Manager
    @Published var technicianJobCounts: [TechnicianJobCount] = []
    
    // New Metrics
    @Published var jobsByStatus: [StatusDistribution] = []
    @Published var jobsByPriority: [PriorityDistribution] = []

    struct StatusDistribution: Identifiable {
        let id = UUID()
        let status: String
        let count: Int
    }

    struct PriorityDistribution: Identifiable {
        let id = UUID()
        let priority: String
        let count: Int
    }

    private let localStorage = LocalStorageService.shared

    func load(organizationId: String, userId: String, role: String, isOnline: Bool, technicianId: String? = nil) {
        let assignedUserId = (role == "TECHNICIAN") ? userId : nil
        jobs = filteredJobs(organizationId: organizationId, userId: assignedUserId, technicianId: technicianId)
        technicians = localStorage.fetchUsers(organizationId: organizationId)
            .filter { $0.role.uppercased() == "TECHNICIAN" }
        computeStats(from: jobs)
        computeComparison(organizationId: organizationId, role: role, userId: userId, technicianId: technicianId)

        guard isOnline else { return }
        SyncManager.shared.startSyncing(organizationId: organizationId, userId: userId, role: role) { [weak self] in
            guard let self = self else { return }
            let refreshed = self.filteredJobs(organizationId: organizationId, userId: assignedUserId, technicianId: technicianId)
            DispatchQueue.main.async {
                self.jobs = refreshed
                self.computeStats(from: refreshed)
                self.computeComparison(organizationId: organizationId, role: role, userId: userId, technicianId: technicianId)
                self.technicians = self.localStorage.fetchUsers(organizationId: organizationId)
                    .filter { $0.role.uppercased() == "TECHNICIAN" }
            }
        }
    }

    private func filteredJobs(organizationId: String, userId: String?, technicianId: String?) -> [Job] {
        let all = localStorage.fetchJobs(organizationId: organizationId, userId: userId)
        guard let technicianId = technicianId, !technicianId.isEmpty else { return all }
        return all.filter { $0.assignedUserId == technicianId }
    }

    private func computeStats(from jobs: [Job]) {
        let calendar = Calendar.current
        let now = Date()
        
        let filteredByTime = jobs.filter { job in
            switch selectedTimeFilter {
            case .sevenDays:
                return calendar.isDate(job.scheduledAt, withinDays: 7, from: now)
            case .month:
                return calendar.isDate(job.scheduledAt, inSameMonthAs: now)
            case .year:
                return calendar.isDate(job.scheduledAt, inSameYearAs: now)
            }
        }
        
        weeklyStats = makeWeeklyStats(from: filteredByTime)
        efficiencyStats = makeEfficiencyStats(from: filteredByTime)
        completionRate = calculateCompletionRate(for: filteredByTime)

        let activeJobs = filteredByTime.filter { $0.status.uppercased() != "CANCELLED" }
        let completedJobsCount = activeJobs.filter { $0.status.uppercased() == "COMPLETED" }.count
        onScheduleRate = activeJobs.isEmpty ? 0 : Double(completedJobsCount) / Double(activeJobs.count)
        
        let statusMap = Dictionary(grouping: filteredByTime, by: { $0.status.uppercased() })
        jobsByStatus = statusMap.map { StatusDistribution(status: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            
        pendingCount = filteredByTime.filter { $0.status.uppercased() == "PENDING" }.count
        startedCount = filteredByTime.filter { $0.status.uppercased() == "STARTED" || $0.status.uppercased() == "IN-PROGRESS" }.count
        onHoldCount = filteredByTime.filter { $0.status.uppercased() == "ON-HOLD" || $0.status.uppercased() == "HOLD" }.count
        cancelledCount = filteredByTime.filter { $0.status.uppercased() == "CANCELLED" }.count
        completedCount = filteredByTime.filter { $0.status.uppercased() == "COMPLETED" }.count

        let techMap = Dictionary(grouping: filteredByTime, by: { $0.assignedUserId })
        technicianJobCounts = technicians.map { tech in
            let techJobs = techMap[tech.id] ?? []
            let completed = techJobs.filter { $0.status.uppercased() == "COMPLETED" }.count
            return TechnicianJobCount(id: tech.id, name: tech.displayName.isEmpty ? tech.username : tech.displayName, assigned: techJobs.count, completed: completed)
        }
        
        let priorityMap = Dictionary(grouping: filteredByTime, by: { $0.priority.uppercased() })
        jobsByPriority = priorityMap.map { PriorityDistribution(priority: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    private func computeComparison(organizationId: String, role: String, userId: String, technicianId: String?) {
        let assignedUserId = (role == "TECHNICIAN") ? userId : nil
        let allJobs = localStorage.fetchJobs(organizationId: organizationId, userId: assignedUserId)
        let teamRate = calculateCompletionRate(for: allJobs)
        let targetRate = 0.8

        if technicianId == nil {
            comparisonLabel = "Vs. Target Average"
            comparisonDelta = completionRate - targetRate
        } else {
            comparisonLabel = "Vs. Team Average"
            comparisonDelta = completionRate - teamRate
        }

        comparisonIsPositive = comparisonDelta >= 0
    }

    private func calculateCompletionRate(for jobs: [Job]) -> Double {
        let activeJobs = jobs.filter { $0.status.uppercased() != "CANCELLED" }
        let total = activeJobs.count
        let completed = activeJobs.filter { $0.status.uppercased() == "COMPLETED" }.count
        return total == 0 ? 0 : Double(completed) / Double(total)
    }

    private func makeWeeklyStats(from jobs: [Job]) -> [WeeklyJobStat] {
        let calendar = Calendar.current
        let today = Date()
        var stats: [WeeklyJobStat] = []

        for offset in (0..<4).reversed() {
            let start = calendar.date(byAdding: .day, value: -(offset * 7), to: startOfWeek(for: today)) ?? today
            let end = calendar.date(byAdding: .day, value: 7, to: start) ?? today
            let weekJobs = jobs.filter { $0.scheduledAt >= start && $0.scheduledAt < end }
            let nonCancelledWeekJobs = weekJobs.filter { $0.status.uppercased() != "CANCELLED" }
            let completed = nonCancelledWeekJobs.filter { $0.status.uppercased() == "COMPLETED" }.count
            let label = "WEEK \(4 - offset)"
            stats.append(WeeklyJobStat(label: label, total: nonCancelledWeekJobs.count, completed: completed))
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
            let nonCancelledDayJobs = dayJobs.filter { $0.status.uppercased() != "CANCELLED" }
            let completed = nonCancelledDayJobs.filter { $0.status.uppercased() == "COMPLETED" }.count
            let rate = nonCancelledDayJobs.isEmpty ? 0.5 : Double(completed) / Double(nonCancelledDayJobs.count)
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

extension Calendar {
    func isDate(_ date: Date, withinDays days: Int, from now: Date) -> Bool {
        guard let cutoff = self.date(byAdding: .day, value: -days, to: now) else { return false }
        return date >= cutoff && date <= now
    }
    
    func isSameMonthAs(_ date1: Date, _ date2: Date) -> Bool {
        let comp1 = dateComponents([.year, .month], from: date1)
        let comp2 = dateComponents([.year, .month], from: date2)
        return comp1.year == comp2.year && comp1.month == comp2.month
    }

    func isSameYearAs(_ date1: Date, _ date2: Date) -> Bool {
        let comp1 = dateComponents([.year], from: date1)
        let comp2 = dateComponents([.year], from: date2)
        return comp1.year == comp2.year
    }
    
    func isDate(_ date: Date, inSameMonthAs now: Date) -> Bool {
        return isSameMonthAs(date, now)
    }
    
    func isDate(_ date: Date, inSameYearAs now: Date) -> Bool {
        return isSameYearAs(date, now)
    }
}
