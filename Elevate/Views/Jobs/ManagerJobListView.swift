import SwiftUI

struct ManagerJobListView: View {
    @EnvironmentObject private var appSession: AppSession
    @Environment(\.managerTabRouter) private var router
    @StateObject private var viewModel = JobsViewModel()
    @ObservedObject private var network = NetworkService.shared
    @State private var selectedFilter = 0

    var body: some View {
        ZStack {
            Color.elevateLightGray.opacity(0.3).ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Nav
                BrandHeaderNav(showOnlineStatus: false, isManager: true)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Search
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.elevateTextGray)
                            TextField("Search jobs", text: $viewModel.searchText)
                                .scaledFont(size: 14)
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)

                        // Filters Segment
                        HStack(spacing: 0) {
                            FilterButton(title: "Today", isSelected: selectedFilter == 0) { selectedFilter = 0; viewModel.selectedFilter = .today }
                            FilterButton(title: "Upcoming", isSelected: selectedFilter == 1) { selectedFilter = 1; viewModel.selectedFilter = .upcoming }
                            FilterButton(title: "Completed", isSelected: selectedFilter == 2) { selectedFilter = 2; viewModel.selectedFilter = .completed }
                        }
                        .padding(4)
                        .background(Color.elevateLightGray)
                        .cornerRadius(8)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)

                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CURRENT SCHEDULE")
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(.elevateTextGray)
                                .textCase(.uppercase)

                            Text(todayString())
                                .scaledFont(size: 24, weight: .bold, design: .rounded)
                                .foregroundColor(.elevateDarkGreen)
                        }
                        .padding(.horizontal, 24)

                        // Job Cards
                        if viewModel.filteredJobs.isEmpty {
                            EmptyStateCard()
                        } else {
                            VStack(spacing: 16) {
                                ForEach(viewModel.filteredJobs, id: \.id) { job in
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
            }
        }
        .navigationBarHidden(true)
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

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

}

private struct ManagerJobCard: View {
    let job: Job

    var body: some View {
        JobCardContent(job: job)
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 24)
    }
}

#Preview {
    ManagerJobListView()
        .environmentObject(AppSession())
}
