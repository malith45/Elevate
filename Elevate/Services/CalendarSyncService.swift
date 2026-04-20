import Foundation
import EventKit

final class CalendarSyncService {
    static let shared = CalendarSyncService()

    private let eventStore = EKEventStore()
    private let jobsCalendarTitle = "Elevate Jobs"

    private init() {}

    func syncJobsIfAuthorized(_ jobs: [Job]) {
        guard isAuthorized else { return }
        syncJobs(jobs)
    }

    private var isAuthorized: Bool {
        if #available(iOS 17.0, *) {
            return EKEventStore.authorizationStatus(for: .event) == .fullAccess
        }
        return legacyIsAuthorized(EKEventStore.authorizationStatus(for: .event))
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
        return suffix.split(separator: "\n").first.map(String.init)
    }

    @available(iOS, introduced: 13.0, deprecated: 17.0)
    private func legacyIsAuthorized(_ status: EKAuthorizationStatus) -> Bool {
        let legacyAuthorizedRawValue = 3
        return status.rawValue == legacyAuthorizedRawValue
    }
}
