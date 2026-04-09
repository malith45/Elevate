import SwiftUI
import EventKit

struct TechnicianCalendarView: View {
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = CalendarViewModel()
    private let localStorage = LocalStorageService.shared
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Calendar Header
                        HStack {
                            Text(monthTitle(from: viewModel.currentMonth))
                                .scaledFont(size: 24, weight: .bold, design: .rounded)

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
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.elevateDarkGreen)
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
                                .foregroundColor(.elevateDarkGreen)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color.elevateDarkGreen.opacity(0.1))
                                .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                        
                        if viewModel.authorizationStatus == .denied || viewModel.authorizationStatus == .restricted {
                            Text("Enable Calendar access to see your events.")
                                .scaledFont(size: 14)
                                .foregroundColor(.elevateTextGray)
                                .padding(.horizontal, 24)
                        }

                        // Calendar Grid
                        VStack(spacing: 16) {
                            // Days of week
                            HStack {
                                ForEach(["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"], id: \.self) { day in
                                    Text(day)
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(.elevateTextGray)
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
                                                .foregroundColor(isSelected ? .white : .black)
                                                .frame(width: 32, height: 32)
                                                .background(isSelected ? Color.elevateDarkGreen : Color.clear)
                                                .cornerRadius(16)
                                                .onTapGesture {
                                                    viewModel.selectedDate = date
                                                }

                                            Circle()
                                                .fill(viewModel.hasEvents(on: date) ? Color.elevateDarkGreen : Color.clear)
                                                .frame(width: 4, height: 4)
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
                                    .foregroundColor(.elevateTextGray)

                                Spacer()

                                Text("\(events.count) EVENTS")
                                    .scaledFont(size: 10, weight: .bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.elevateDarkGreen.opacity(0.1))
                                    .foregroundColor(.elevateDarkGreen)
                                    .cornerRadius(8)
                            }

                            if events.isEmpty {
                                HStack {
                                    Spacer()
                                    Text("No events scheduled for this day")
                                        .scaledFont(size: 14)
                                        .foregroundColor(.elevateTextGray)
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
                                            dotColor: .elevateDarkGreen
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
    }
}

struct JobCalendarRow: View {
    var time: String
    var ampm: String
    var title: String
    var location: String
    var dotColor: Color
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(spacing: 2) {
                Text(time)
                    .scaledFont(size: 14, weight: .bold)
                Text(ampm)
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundColor(.elevateTextGray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .scaledFont(size: 16, weight: .bold)
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 10))
                    Text(location)
                        .scaledFont(size: 12)
                }
                .foregroundColor(.elevateTextGray)
            }
            Spacer()
            
            HStack(spacing: 8) {
                Circle().fill(dotColor).frame(width: 8, height: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.elevateTextGray)
            }
        }
    }
}

#Preview {
    TechnicianCalendarView()
}

private extension TechnicianCalendarView {
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
        let refreshLocal = {
            let jobs = localStorage.fetchJobs(organizationId: user.organizationId)
                .filter { $0.assignedUserId == user.id }
            self.viewModel.syncJobsIfAuthorized(jobs)
            self.viewModel.loadEventsIfAuthorized()
        }

        if NetworkService.shared.isOnline {
            SyncManager.shared.startSyncing(organizationId: user.organizationId, userId: user.id) {
                refreshLocal()
            }
        } else {
            refreshLocal()
        }
    }
}
