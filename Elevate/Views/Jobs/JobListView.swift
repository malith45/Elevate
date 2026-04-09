import SwiftUI

struct JobListView: View {
    @EnvironmentObject private var appSession: AppSession
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = JobsViewModel()
    @ObservedObject private var network = NetworkService.shared
    @State private var selectedFilter = 0
    
    var body: some View {
        ZStack {
            Color.elevateLightGray.opacity(0.3).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BrandHeaderNav(showOnlineStatus: false)
                
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
                        VStack(spacing: 16) {
                            ForEach(viewModel.filteredJobs, id: \.id) { job in
                                JobCard(job: job)
                            }
                        }
                        
                        // Bottom Stats
                        HStack(spacing: 16) {
                            StatPill(icon: "checkmark.circle", value: "\(viewModel.jobs.filter { $0.status.uppercased() == "COMPLETED" }.count)", title: "JOBS COMPLETED", isPrimary: true)
                            StatPill(icon: "clock", value: "\(viewModel.jobs.filter { $0.status.uppercased() != "COMPLETED" }.count)", title: "PENDING JOBS", isPrimary: false)
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

struct FilterButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .scaledFont(size: 14, weight: .bold)
                .foregroundColor(isSelected ? .elevateDarkGreen : .elevateTextGray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.white : Color.clear)
                .cornerRadius(6)
                .shadow(color: isSelected ? Color.black.opacity(0.05) : Color.clear, radius: 2, x: 0, y: 1)
        }
    }
}

struct JobCard: View {
    var job: Job
    
    var body: some View {
        NavigationLink(destination: JobDetailsView(jobId: job.id)) {
            JobCardContent(job: job)
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

struct JobCardContent: View {
    var job: Job

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
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct StatPill: View {
    var icon: String
    var value: String
    var title: String
    var isPrimary: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(isPrimary ? .white : .black)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .scaledFont(size: 28, weight: .bold)
                    .foregroundColor(isPrimary ? .white : .black)
                Text(title)
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundColor(isPrimary ? .white.opacity(0.8) : .elevateTextGray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(isPrimary ? Color.elevateDarkGreen : Color.elevateLightGray)
        .cornerRadius(12)
    }
}

#Preview {
    JobListView()
        .environmentObject(AppSession())
}
