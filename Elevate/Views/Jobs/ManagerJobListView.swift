import SwiftUI

struct ManagerJobListView: View {
    @EnvironmentObject private var appSession: AppSession
    @Environment(\.managerTabRouter) private var router
    @StateObject private var viewModel = JobsViewModel()
    @ObservedObject private var network = NetworkService.shared
    @State private var selectedFilter = 0
    @ObservedObject var settings = AccessibilitySettings.shared

    var body: some View {
        ZStack {
            (settings.isHighContrast ? Color.black : Color.elevateLightGray.opacity(0.3)).ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Nav
                BrandHeaderNav(showOnlineStatus: false, isManager: true)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Search
                        CustomSearchBar(text: $viewModel.searchText, placeholder: "Search jobs")
                        .padding(.horizontal, 24)
                        .padding(.top, 12)

                        // Filters Segment
                        HStack(spacing: 0) {
                            FilterButton(title: "Today", isSelected: selectedFilter == 0) { selectedFilter = 0; viewModel.selectedFilter = .today }
                            FilterButton(title: "Upcoming", isSelected: selectedFilter == 1) { selectedFilter = 1; viewModel.selectedFilter = .upcoming }
                            FilterButton(title: "Completed", isSelected: selectedFilter == 2) { selectedFilter = 2; viewModel.selectedFilter = .completed }
                        }
                        .padding(4)
                        .background(settings.isHighContrast ? Color.black : settings.surfaceColor)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)

                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CURRENT SCHEDULE")
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(.elevateTextGray)
                                .tracking(1)
                                .textCase(.uppercase)
                            
                            Text(todayString())
                                .scaledFont(size: 24, weight: .bold, design: .rounded)
                                .foregroundColor(settings.isHighContrast ? settings.primaryText : settings.accentColor)
                        }
                        .padding(.horizontal, 24)

                        // Job Cards
                        VStack(spacing: 24) {
                            if viewModel.selectedFilter == .upcoming {
                                let past = pastJobs()
                                let future = upcomingJobs()
                                
                                if !past.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("PAST JOBS")
                                            .scaledFont(size: 10, weight: .bold)
                                            .foregroundColor(.red)
                                            .tracking(1)
                                            .padding(.horizontal, 24)
                                        
                                        ForEach(past) { job in
                                            Button(action: {
                                                router.selectedJobId = job.id
                                                router.currentScreen = .jobDetails
                                                router.selectedTab = .jobs
                                            }) {
                                                ManagerJobCard(job: job)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                
                                if !future.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("UPCOMING JOBS")
                                            .scaledFont(size: 10, weight: .bold)
                                            .foregroundColor(.elevateDarkGreen)
                                            .tracking(1)
                                            .padding(.horizontal, 24)
                                        
                                        ForEach(future) { job in
                                            Button(action: {
                                                router.selectedJobId = job.id
                                                router.currentScreen = .jobDetails
                                                router.selectedTab = .jobs
                                            }) {
                                                ManagerJobCard(job: job)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                
                                if past.isEmpty && future.isEmpty {
                                    emptyState
                                }
                            } else {
                                if viewModel.filteredJobs.isEmpty {
                                    emptyState
                                } else {
                                    ForEach(viewModel.filteredJobs) { job in
                                        Button(action: {
                                            router.selectedJobId = job.id
                                            router.currentScreen = .jobDetails
                                            router.selectedTab = .jobs
                                        }) {
                                            ManagerJobCard(job: job)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)

                        // Bottom Stats
                        HStack(spacing: 16) {
                            let completedCount = viewModel.jobs.filter { $0.status.uppercased() == "COMPLETED" }.count
                            let pendingCount = viewModel.jobs.filter { $0.status.uppercased() != "COMPLETED" }.count
                            StatPill(icon: "checkmark.circle", value: "\(completedCount)", title: "JOBS COMPLETED", isPrimary: true)
                            StatPill(icon: "clock", value: "\(pendingCount)", title: "PENDING JOBS", isPrimary: false)
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
        .speakOnAppear("Manager Job Administration")
        .onAppear {
            if let user = appSession.currentUser {
                viewModel.loadJobs(organizationId: user.organizationId, userId: user.id, isOnline: network.isOnline)
            }
        }
        .onChange(of: network.isOnline) { _, isOnline in
            if let user = appSession.currentUser {
                viewModel.loadJobs(organizationId: user.organizationId, userId: user.id, isOnline: isOnline)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 44))
                .foregroundColor(.gray.opacity(0.3))
            Text("No jobs found for this filter")
                .scaledFont(size: 14)
                .foregroundColor(settings.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func pastJobs() -> [Job] {
        let today = Calendar.current.startOfDay(for: Date())
        return viewModel.filteredJobs.filter { $0.scheduledAt < today }
    }

    private func upcomingJobs() -> [Job] {
        let today = Calendar.current.startOfDay(for: Date())
        return viewModel.filteredJobs.filter { $0.scheduledAt >= today }
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

}

private struct ManagerJobCard: View {
    let job: Job
    @ObservedObject var settings = AccessibilitySettings.shared

    var body: some View {
        HStack(spacing: 0) {
            // Left Status Strip
            Rectangle()
                .fill(statusColor)
                .frame(width: 6)
            
            VStack(alignment: .leading, spacing: 16) {
                // Top Row: Status Pill & Time
                HStack {
                    Text(job.status.uppercased())
                        .scaledFont(size: 9, weight: .bold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(statusColor.opacity(0.12))
                        .foregroundColor(statusColor)
                        .cornerRadius(20)
                    
                    Spacer()
                    
                    Text(timeString(from: job.scheduledAt))
                        .scaledFont(size: 14, weight: .bold)
                        .foregroundColor(settings.secondaryText)
                }
                
                // Title
                Text(job.title)
                    .scaledFont(size: 18, weight: .bold, design: .rounded)
                    .foregroundColor(settings.primaryText)
                    .lineLimit(2)
                
                // Location Section
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.elevateLightGray.opacity(0.3))
                            .frame(width: 36, height: 36)
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(settings.accentColor)
                            .font(.system(size: 16))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(job.location)
                            .scaledFont(size: 14, weight: .bold)
                            .foregroundColor(settings.primaryText)
                            .lineLimit(1)
                        if let notes = job.notes, !notes.isEmpty {
                            Text(notes)
                                .scaledFont(size: 12)
                                .foregroundColor(settings.secondaryText)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(settings.isHighContrast ? Color.black : .white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(settings.isHighContrast ? Color.white : settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(settings.isHighContrast ? 0 : 0.08), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 24)
    }

    private var statusColor: Color {
        if job.isUrgent { return .red }
        switch job.status.uppercased() {
        case "COMPLETED": return .elevateDarkGreen
        case "IN PROGRESS": return .blue
        case "CANCELLED": return .gray
        default: return settings.accentColor
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    ManagerJobListView()
        .environmentObject(AppSession())
}
