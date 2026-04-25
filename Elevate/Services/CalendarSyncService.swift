import Foundation
import EventKit
import FirebaseFirestore

final class CalendarSyncService {
    static let shared = CalendarSyncService()
    let eventStore = EKEventStore()
    private let jobsCalendarTitle = "Elevate Jobs"

    private var isSyncingToCalendar = false
    private var lastSyncOrganizationId: String?

    private init() {}

    func startMonitoring(organizationId: String) {
        self.lastSyncOrganizationId = organizationId
        NotificationCenter.default.removeObserver(self, name: .EKEventStoreChanged, object: eventStore)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(eventStoreChanged),
            name: .EKEventStoreChanged,
            object: eventStore
        )
    }

    @objc private func eventStoreChanged() {
        // Prevent feedback loops if we just updated the calendar ourselves
        guard !isSyncingToCalendar, let organizationId = lastSyncOrganizationId else { return }
        
        // Use a slight delay to allow the event store to settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.syncBackFromCalendar(organizationId: organizationId)
        }
    }

    private func syncBackFromCalendar(organizationId: String) {
        guard isAuthorized, let jobsCalendar = ensureJobsCalendar() else { return }
        
        let now = Date()
        let start = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
        let end = Calendar.current.date(byAdding: .month, value: 3, to: now) ?? now
        
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: [jobsCalendar])
        let events = eventStore.events(matching: predicate)
        
        let localJobs = LocalStorageService.shared.fetchJobs(organizationId: organizationId)
        // Use a dictionary initializer that handles duplicate keys to prevent runtime crashes
        let jobMap = Dictionary(localJobs.map { ($0.id, $0) }, uniquingKeysWith: { (first, _) in first })
        
        var jobsToUpdate: [Job] = []
        
        for event in events {
            guard let notes = event.notes, let jobId = jobId(from: notes) else {
                continue
            }
            
            guard let job = jobMap[jobId] else {
                print("CalendarSync: Event found with Elevate ID \(jobId) but no matching job in local DB.")
                continue
            }
            
            // Check if the time has changed in the calendar
            if let eventStart = event.startDate, abs(eventStart.timeIntervalSince(job.scheduledAt)) > 1 {
                print("CalendarSync: Detected time change for job \(job.id). New time: \(eventStart)")
                
                var updatedJob = job
                updatedJob.scheduledAt = eventStart
                updatedJob.updatedAt = Date()
                jobsToUpdate.append(updatedJob)
            }
        }
        
        if !jobsToUpdate.isEmpty {
            LocalStorageService.shared.saveJobs(jobsToUpdate)
            
            // Push updates to Firebase
            for job in jobsToUpdate {
                FirebaseService.shared.updateJobFields(
                    jobId: job.id,
                    fields: [
                        "scheduledAt": Timestamp(date: job.scheduledAt),
                        "updatedAt": Timestamp(date: job.updatedAt)
                    ]
                ) { _ in }
            }
            
            // Notify the app that jobs have changed
            NotificationCenter.default.post(name: .jobStatusDidChange, object: nil)
        }
    }

    func syncJobsIfAuthorized(_ jobs: [Job]) {
        guard isAuthorized else { return }
        isSyncingToCalendar = true
        syncJobs(jobs)
        isSyncingToCalendar = false
    }

    private var isAuthorized: Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, *) {
            return status == .fullAccess || status == .writeOnly
        } else {
            return status.rawValue == 3 // .authorized
        }
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

        for job in jobs {
            let event = eventByJobId[job.id] ?? EKEvent(eventStore: eventStore)
            
            // Only update if something actually changed to avoid unnecessary event store cycles
            if eventByJobId[job.id] != nil && 
               abs(event.startDate.timeIntervalSince(job.scheduledAt)) < 1 &&
               event.title == job.title &&
               event.location == job.location {
                continue
            }
            
            event.calendar = jobsCalendar
            event.title = job.title
            event.startDate = job.scheduledAt
            event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: job.scheduledAt) ?? job.scheduledAt
            event.location = job.location
            event.notes = jobNotes(for: job)
            
            do {
                try eventStore.save(event, span: .thisEvent)
            } catch {
                print("CalendarSync: Failed to save event for job \(job.id): \(error)")
            }
        }
        
        try? eventStore.commit()
    }
    
    func cleanupDuplicates() {
        guard isAuthorized, let jobsCalendar = ensureJobsCalendar() else { return }
        
        let now = Date()
        let start = Calendar.current.date(byAdding: .month, value: -6, to: now) ?? now
        let end = Calendar.current.date(byAdding: .month, value: 6, to: now) ?? now
        
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: [jobsCalendar])
        let events = eventStore.events(matching: predicate)
        
        var seenJobIds = Set<String>()
        var duplicates: [EKEvent] = []
        
        for event in events {
            if let jobId = jobId(from: event.notes) {
                if seenJobIds.contains(jobId) {
                    duplicates.append(event)
                } else {
                    seenJobIds.insert(jobId)
                }
            }
        }
        
        for duplicate in duplicates {
            try? eventStore.remove(duplicate, span: .thisEvent)
        }
        
        if !duplicates.isEmpty {
            try? eventStore.commit()
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
}
