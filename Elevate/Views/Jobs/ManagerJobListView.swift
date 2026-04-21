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
            settings.appBackground.ignoresSafeArea()

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
                        .background(settings.surfaceColor)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 4)

                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CURRENT SCHEDULE")
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(settings.secondaryText)
                                .textCase(.uppercase)
                            
                            Text(todayString())
                                .scaledFont(size: 24, weight: .bold, design: .rounded)
                                .foregroundColor(settings.accentColor)
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
                                            .scaledFont(size: 12, weight: .bold)
                                            .foregroundColor(.red)
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
                                            .scaledFont(size: 12, weight: .bold)
                                            .foregroundColor(.elevateDarkGreen)
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
        JobCardContent(job: job)
        .padding(20)
        .background(settings.surfaceColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 24)
    }
}

#Preview {
    ManagerJobListView()
        .environmentObject(AppSession())
}
