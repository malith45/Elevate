import SwiftUI
import EventKit

struct ManagerCalendarView: View {
    @Environment(\.managerTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = CalendarViewModel()
    @ObservedObject var settings = AccessibilitySettings.shared
    @State private var isShowingEventEditor = false
    @State private var shouldOpenEventEditor = false
    private let localStorage = LocalStorageService.shared
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav(isManager: true, onBack: {
                    router.currentScreen = .dashboard
                    router.selectedTab = .dashboard
                })
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Calendar Header
                        HStack {
                            Text(monthTitle(from: viewModel.currentMonth))
                                .scaledFont(size: 24, weight: .bold, design: .rounded)
                                .foregroundColor(settings.primaryText)

                            Spacer()

                            HStack(spacing: 24) {
                                Button(action: {
                                    viewModel.changeMonth(by: -1)
                                }) {
                                    Image(systemName: "chevron.left")
                                }
                                Button(action: {
                                    viewModel.changeMonth(by: 1)
                                }) {
                                    Image(systemName: "chevron.right")
                                }
                                
                                // Manager Adding Events Button
                                Button(action: {
                                    if viewModel.isAuthorized {
                                        isShowingEventEditor = true
                                    } else {
                                        shouldOpenEventEditor = true
                                        viewModel.requestAccessIfNeeded()
                                    }
                                }) {
                                    Image(systemName: "plus")
                                        .frame(width: 28, height: 28)
                                        .background(settings.isHighContrast ? Color.black : settings.accentColor.opacity(0.1))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 1)
                                        )
                                }
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(settings.accentColor)
                        }
                        .padding(.horizontal, 24)
                        
                        // Today Badge
                        Button(action: {
                            let today = Date()
                            viewModel.currentMonth = today
                            viewModel.selectedDate = today
                            viewModel.loadEventsIfAuthorized()
                        }) {
                            Text("Today")
                                .scaledFont(size: 14, weight: .medium)
                                .foregroundColor(settings.isHighContrast ? .white : settings.accentColor)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(settings.isHighContrast ? Color.black : settings.accentColor.opacity(0.1))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                        
                        if viewModel.authorizationStatus == .denied || viewModel.authorizationStatus == .restricted {
                            Text("Enable Calendar access to see your events.")
                                .scaledFont(size: 14)
                                .foregroundColor(settings.secondaryText)
                                .padding(.horizontal, 24)
                        }

                        // Calendar Grid
                        VStack(spacing: 16) {
                            // Days of week
                            HStack {
                                ForEach(["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"], id: \.self) { day in
                                    Text(day)
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(settings.secondaryText)
                                        .frame(maxWidth: .infinity)
                                }
                            }

                            // Dates
                            LazyVGrid(columns: columns, spacing: 16) {
                                let days = viewModel.monthGridDates()
                                ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                                    if let date = date {
                                        let isSelected = Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate)
                                        VStack(spacing: 4) {
                                            Text("\(Calendar.current.component(.day, from: date))")
                                                .scaledFont(size: 16)
                                                .foregroundColor(isSelected ? .white : settings.primaryText)
                                                .frame(width: 32, height: 32)
                                                .background(isSelected ? (settings.isHighContrast ? Color.black : settings.accentColor) : Color.clear)
                                                .cornerRadius(16)
                                                .overlay(
                                                    Circle()
                                                        .stroke(isSelected && settings.isHighContrast ? Color.white : Color.clear, lineWidth: 2)
                                                )
                                                .onTapGesture {
                                                    viewModel.selectedDate = date
                                                }

                                            Circle()
                                                .fill(viewModel.hasEvents(on: date) ? settings.accentColor : Color.clear)
                                                .frame(width: 4, height: 4)
                                                .overlay(
                                                    Circle()
                                                        .stroke(viewModel.hasEvents(on: date) && settings.isHighContrast ? Color.white : Color.clear, lineWidth: 0.5)
                                                )
                                        }
                                    } else {
                                        Color.clear
                                            .frame(width: 32, height: 32)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Divider().padding(.vertical, 8)
                        
                        // Events List
                        VStack(alignment: .leading, spacing: 16) {
                            let events = viewModel.events(for: viewModel.selectedDate)

                            HStack {
                                Text(dayHeader(from: viewModel.selectedDate))
                                    .scaledFont(size: 12, weight: .bold)
                                    .foregroundColor(settings.secondaryText)

                                Spacer()

                                Text("\(events.count) EVENTS")
                                    .scaledFont(size: 10, weight: .bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(settings.isHighContrast ? Color.black : settings.accentColor.opacity(0.1))
                                    .foregroundColor(settings.isHighContrast ? .white : settings.accentColor)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 1)
                                    )
                            }

                            if events.isEmpty {
                                HStack {
                                    Spacer()
                                    Text("No events scheduled for this day")
                                        .scaledFont(size: 14)
                                        .foregroundColor(settings.secondaryText)
                                    Spacer()
                                }
                            } else {
                                VStack(spacing: 24) {
                                    ForEach(events, id: \.eventIdentifier) { event in
                                        let timeParts = timeParts(for: event)
                                        JobCalendarRow(
                                            time: timeParts.time,
                                            ampm: timeParts.ampm,
                                            title: event.title,
                                            location: event.location ?? "No location",
                                            dotColor: settings.accentColor
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 96)
                }
            }
            
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.requestAccessIfNeeded()
            syncJobs()
        }
        .onChange(of: viewModel.currentMonth) { _, _ in
            viewModel.loadEventsIfAuthorized()
            syncJobs()
        }
        .onChange(of: viewModel.authorizationStatus) { _, _ in
            if shouldOpenEventEditor, viewModel.isAuthorized {
                shouldOpenEventEditor = false
                isShowingEventEditor = true
            }
        }
        .sheet(isPresented: $isShowingEventEditor) {
            EventEditViewController(eventStore: viewModel.eventStore) {
                // Refresh calendar state upon creation/dismmissal
                viewModel.loadEventsIfAuthorized()
            }
        }
    }
}

#Preview {
    ManagerCalendarView()
}

private extension ManagerCalendarView {
    func monthTitle(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    func dayHeader(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date).uppercased()
    }

    func timeParts(for event: EKEvent) -> (time: String, ampm: String) {
        if event.isAllDay {
            return ("All", "Day")
        }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm"
        let ampmFormatter = DateFormatter()
        ampmFormatter.dateFormat = "a"
        return (timeFormatter.string(from: event.startDate), ampmFormatter.string(from: event.startDate))
    }

    func syncJobs() {
        guard let user = appSession.currentUser else { return }
        let jobs = localStorage.fetchJobs(organizationId: user.organizationId)
        viewModel.syncJobsIfAuthorized(jobs)
        viewModel.loadEventsIfAuthorized()
    }
}
