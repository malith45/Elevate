import Foundation
import Combine
import EventKit

final class CalendarViewModel: ObservableObject {
    @Published var currentMonth: Date
    @Published var selectedDate: Date
    @Published var eventsByDay: [Date: [EKEvent]] = [:]
    @Published var authorizationStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    @Published var errorMessage: String?

    let eventStore = EKEventStore()
    private let jobsCalendarTitle = "Elevate Jobs"

    init() {
        let now = Date()
        currentMonth = now
        selectedDate = now
    }

    var isAuthorized: Bool {
        if #available(iOS 17.0, *) {
            return authorizationStatus == .fullAccess
        } else {
            return legacyIsAuthorized(authorizationStatus)
        }
    }

    func requestAccessIfNeeded() {
        let status = EKEventStore.authorizationStatus(for: .event)
        authorizationStatus = status

        if #available(iOS 17.0, *) {
            switch status {
            case .fullAccess:
                loadEvents(for: currentMonth)
            case .notDetermined:
                eventStore.requestFullAccessToEvents { [weak self] granted, error in
                    DispatchQueue.main.async {
                        self?.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                        if let error = error {
                            self?.errorMessage = error.localizedDescription
                        }
                        if granted {
                            self?.loadEvents(for: self?.currentMonth ?? Date())
                        }
                    }
                }
            default:
                errorMessage = "Calendar access is disabled."
            }
        } else {
            if legacyIsAuthorized(status) {
                loadEvents(for: currentMonth)
            } else if status == .notDetermined {
                requestLegacyAccess { [weak self] granted, error in
                    DispatchQueue.main.async {
                        self?.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                        if let error = error {
                            self?.errorMessage = error.localizedDescription
                        }
                        if granted {
                            self?.loadEvents(for: self?.currentMonth ?? Date())
                        }
                    }
                }
            } else {
                errorMessage = "Calendar access is disabled."
            }
        }
    }

    func loadEventsIfAuthorized() {
        if isAuthorized {
            loadEvents(for: currentMonth)
        }
    }

    func syncJobsIfAuthorized(_ jobs: [Job]) {
        guard isAuthorized else { return }
        syncJobs(jobs)
    }

    func loadEvents(for month: Date) {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        guard let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: 0), to: startOfMonth) else {
            return
        }

        let predicate = eventStore.predicateForEvents(withStart: startOfMonth, end: endOfMonth, calendars: nil)
        let events = eventStore.events(matching: predicate)

        let grouped = Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.startDate)
        }

        eventsByDay = grouped
    }

    private func syncJobs(_ jobs: [Job]) {
        guard let jobsCalendar = ensureJobsCalendar() else { return }
        guard let dateRange = jobsDateRange(jobs) else { return }

        let predicate = eventStore.predicateForEvents(withStart: dateRange.start, end: dateRange.end, calendars: [jobsCalendar])
        let existingEvents = eventStore.events(matching: predicate)
        var eventByJobId: [String: EKEvent] = [:]

        existingEvents.forEach { event in
            if let jobId = jobId(from: event.notes) {
                eventByJobId[jobId] = event
            }
        }

        let jobIds = Set(jobs.map { $0.id })
        existingEvents.forEach { event in
            if let jobId = jobId(from: event.notes), !jobIds.contains(jobId) {
                try? eventStore.remove(event, span: .thisEvent)
            }
        }

        jobs.forEach { job in
            let event = eventByJobId[job.id] ?? EKEvent(eventStore: eventStore)
            event.calendar = jobsCalendar
            event.title = job.title
            event.startDate = job.scheduledAt
            event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: job.scheduledAt) ?? job.scheduledAt
            event.location = job.location
            event.notes = jobNotes(for: job)
            try? eventStore.save(event, span: .thisEvent)
        }
    }

    private func ensureJobsCalendar() -> EKCalendar? {
        if let existing = eventStore.calendars(for: .event).first(where: { $0.title == jobsCalendarTitle }) {
            return existing
        }

        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = jobsCalendarTitle
        if let source = eventStore.defaultCalendarForNewEvents?.source {
            calendar.source = source
        } else if let source = eventStore.sources.first(where: { $0.sourceType == .local }) {
            calendar.source = source
        } else {
            calendar.source = eventStore.sources.first
        }

        do {
            try eventStore.saveCalendar(calendar, commit: true)
            return calendar
        } catch {
            errorMessage = "Unable to create calendar."
            return nil
        }
    }

    private func jobsDateRange(_ jobs: [Job]) -> (start: Date, end: Date)? {
        guard let minDate = jobs.map({ $0.scheduledAt }).min(),
              let maxDate = jobs.map({ $0.scheduledAt }).max()
        else { return nil }

        let start = Calendar.current.date(byAdding: .day, value: -1, to: minDate) ?? minDate
        let end = Calendar.current.date(byAdding: .day, value: 2, to: maxDate) ?? maxDate
        return (start, end)
    }

    private func jobNotes(for job: Job) -> String {
        var notes = "ElevateJobId: \(job.id)"
        if let jobNotes = job.notes, !jobNotes.isEmpty {
            notes += "\n\n\(jobNotes)"
        }
        return notes
    }

    private func jobId(from notes: String?) -> String? {
        guard let notes = notes else { return nil }
        let prefix = "ElevateJobId: "
        guard let range = notes.range(of: prefix) else { return nil }
        let idStart = range.upperBound
        let suffix = notes[idStart...]
        let id = suffix.split(separator: "\n").first.map(String.init)
        return id
    }

    func events(for date: Date) -> [EKEvent] {
        let key = Calendar.current.startOfDay(for: date)
        return eventsByDay[key] ?? []
    }

    func hasEvents(on date: Date) -> Bool {
        !events(for: date).isEmpty
    }

    func monthGridDates() -> [Date?] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2

        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth)
        else {
            return []
        }

        let weekday = calendar.component(.weekday, from: startOfMonth)
        let leadingEmpty = (weekday - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leadingEmpty)
        range.forEach { day in
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }

        let trailingEmpty = (7 - (days.count % 7)) % 7
        if trailingEmpty > 0 {
            days.append(contentsOf: Array(repeating: nil, count: trailingEmpty))
        }

        return days
    }

    func changeMonth(by value: Int) {
        if let updated = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = updated
        }
    }

    @available(iOS, introduced: 13.0, deprecated: 17.0)
    private func legacyIsAuthorized(_ status: EKAuthorizationStatus) -> Bool {
        let legacyAuthorizedRawValue = 3
        return status.rawValue == legacyAuthorizedRawValue
    }

    @available(iOS, introduced: 13.0, deprecated: 17.0)
    private func requestLegacyAccess(completion: @escaping (Bool, Error?) -> Void) {
        eventStore.requestAccess(to: .event, completion: completion)
    }
}
