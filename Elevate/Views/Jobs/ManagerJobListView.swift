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
                        let jobsToShow = viewModel.filteredJobs.isEmpty ? demoJobs : viewModel.filteredJobs

                        VStack(spacing: 16) {
                            ForEach(jobsToShow, id: \.id) { job in
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

    private var demoJobs: [Job] {
        let now = Date()
        return [
            Job(
                id: "demo-job-001",
                organizationId: appSession.currentUser?.organizationId ?? "demo-org",
                title: "Inspect Elevator Panel",
                location: "Skyline Corp HQ",
                scheduledAt: now.addingTimeInterval(3600),
                status: "IN_PROGRESS",
                priority: "HIGH",
                assignedUserId: "TECH-3029",
                notes: "Main panel alarm triggered.",
                approvedCost: 12500,
                photoUrls: [],
                updatedAt: now
            )
        ]
    }
}

private struct ManagerJobCard: View {
    let job: Job

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(job.status.uppercased())
                        .scaledFont(size: 10, weight: .bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.elevateLightGray)
                        .foregroundColor(.elevateTextGray)
                        .cornerRadius(12)

                    Text(job.title)
                        .scaledFont(size: 18, weight: .bold)
                }
                Spacer()
                Text(timeString(from: job.scheduledAt))
                    .scaledFont(size: 14, weight: .bold)
            }

            HStack(spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .frame(width: 32, height: 32)
                    .background(Color.elevateLightGray)
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(job.location)
                        .scaledFont(size: 14, weight: .bold)
                    Text(job.notes ?? "")
                        .scaledFont(size: 12)
                        .foregroundColor(.elevateTextGray)
                }
                Spacer()
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 24)
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
