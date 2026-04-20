import SwiftUI

struct JobListView: View {
    @EnvironmentObject private var appSession: AppSession
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = JobsViewModel()
    @ObservedObject private var network = NetworkService.shared
    @State private var selectedFilter = 0
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BrandHeaderNav(showOnlineStatus: false)
                
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
                        .background(settings.isHighContrast ? Color.black : Color.elevateLightGray)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(settings.cardStroke, lineWidth: settings.isHighContrast ? 2 : 0)
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
                                            JobCard(job: job)
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
                                            JobCard(job: job)
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
                                        JobCard(job: job)
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                        
                        // Bottom Stats
                        HStack(spacing: 16) {
                            StatPill(icon: "checkmark.circle", value: "\(viewModel.jobs.filter { $0.status.uppercased() == "COMPLETED" }.count)", title: "JOBS COMPLETED", isPrimary: true)
                            StatPill(icon: "clock", value: "\(viewModel.jobs.filter { $0.status.uppercased() != "COMPLETED" }.count)", title: "PENDING JOBS", isPrimary: false)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 96)
                }
            }
        }
        .navigationBarHidden(true)
        .speakOnAppear("Technician Job Schedule")
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
                .foregroundColor(.gray)
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

struct FilterButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    @ObservedObject var settings = AccessibilitySettings.shared
    var body: some View {
        Button(action: action) {
            Text(title)
                .scaledFont(size: 14, weight: .bold)
                .foregroundColor(isSelected ? settings.accentColor : settings.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? settings.surfaceColor : Color.clear)
                .cornerRadius(6)
                .shadow(color: isSelected && !settings.isHighContrast ? Color.black.opacity(0.05) : Color.clear, radius: 2, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? settings.cardStroke : Color.clear, lineWidth: settings.isHighContrast ? 1 : 0)
                )
        }
    }
}

struct JobCard: View {
    var job: Job
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        NavigationLink(destination: JobDetailsView(jobId: job.id)) {
            JobCardContent(job: job)
        }
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

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct JobCardContent: View {
    var job: Job
    @ObservedObject var settings = AccessibilitySettings.shared

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(job.status.uppercased())
                        .scaledFont(size: 10, weight: .bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(settings.isHighContrast ? Color.black : Color.elevateLightGray)
                        .foregroundColor(settings.isHighContrast ? .white : .elevateTextGray)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(settings.isHighContrast ? .white : Color.clear, lineWidth: settings.isHighContrast ? 1 : 0)
                        )

                    Text(job.title)
                        .scaledFont(size: 18, weight: .bold)
                        .foregroundColor(settings.primaryText)
                }
                Spacer()
                Text(timeString(from: job.scheduledAt))
                    .scaledFont(size: 14, weight: .bold)
                    .foregroundColor(settings.secondaryText)
            }

            HStack(spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .frame(width: 32, height: 32)
                    .background(settings.isHighContrast ? Color.black : Color.elevateLightGray)
                    .foregroundColor(settings.accentColor)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(settings.cardStroke, lineWidth: settings.isHighContrast ? 1 : 0)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(job.location)
                        .scaledFont(size: 14, weight: .bold)
                        .foregroundColor(settings.primaryText)
                    Text(job.notes ?? "")
                        .scaledFont(size: 12)
                        .foregroundColor(settings.secondaryText)
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
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(settings.isHighContrast ? .white : (isPrimary ? .white : .black))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .scaledFont(size: 28, weight: .bold)
                    .foregroundColor(settings.isHighContrast ? .white : (isPrimary ? .white : .black))
                Text(title)
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundColor(settings.isHighContrast ? .white : (isPrimary ? .white.opacity(0.8) : .elevateTextGray))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(settings.isHighContrast ? Color.black : (isPrimary ? Color.elevateDarkGreen : Color.elevateLightGray))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
    }
}

#Preview {
    JobListView()
        .environmentObject(AppSession())
}
