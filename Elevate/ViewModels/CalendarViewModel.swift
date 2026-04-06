import Foundation
import Combine
import EventKit

final class CalendarViewModel: ObservableObject {
    @Published var currentMonth: Date
    @Published var selectedDate: Date
    @Published var eventsByDay: [Date: [EKEvent]] = [:]
    @Published var authorizationStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    @Published var errorMessage: String?

    private let eventStore = EKEventStore()

    init() {
        let now = Date()
        currentMonth = now
        selectedDate = now
    }

    var isAuthorized: Bool {
        if #available(iOS 17.0, *) {
            return authorizationStatus == .fullAccess
        }
        return authorizationStatus == .authorized
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
            return
        }

        switch status {
        case .authorized:
            loadEvents(for: currentMonth)
        case .notDetermined:
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
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
    }

    func loadEventsIfAuthorized() {
        if isAuthorized {
            loadEvents(for: currentMonth)
        }
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
}
