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
                            FilterButton(title: "Today", isSelected: selectedFilter == 0) { 
                                HapticManager.shared.playImpact(style: .light)
                                selectedFilter = 0; viewModel.selectedFilter = .today 
                            }
                            FilterButton(title: "Upcoming", isSelected: selectedFilter == 1) { 
                                HapticManager.shared.playImpact(style: .light)
                                selectedFilter = 1; viewModel.selectedFilter = .upcoming 
                            }
                            FilterButton(title: "Completed", isSelected: selectedFilter == 2) { 
                                HapticManager.shared.playImpact(style: .light)
                                selectedFilter = 2; viewModel.selectedFilter = .completed 
                            }
                        }
                        .padding(4)
                        .background(settings.surfaceColor)
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
                                .foregroundColor(settings.secondaryText)
                                .tracking(1)
                                .textCase(.uppercase)
                            
                            Text(todayString())
                                .scaledFont(size: 24, weight: .bold, design: .rounded)
                                .foregroundColor(settings.accentColor)
                        }
                        .padding(.horizontal, 24)

                        // Job Cards
                        VStack(spacing: 24) {
                            if viewModel.isLoading && viewModel.jobs.isEmpty {
                                ForEach(0..<5) { _ in
                                    SkeletonTaskRow()
                                        .padding(.horizontal, 24)
                                }
                            } else if viewModel.selectedFilter == .upcoming {
                                if viewModel.filteredJobs.isEmpty {
                                    emptyState
                                } else {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("UPCOMING JOBS")
                                            .scaledFont(size: 10, weight: .bold)
                                            .foregroundColor(settings.accentColor)
                                            .tracking(1)
                                            .padding(.horizontal, 24)
                                        
                                        ForEach(viewModel.filteredJobs) { job in
                                            ManagerJobCard(job: job)
                                        }
                                    }
                                }
                            } else if viewModel.selectedFilter == .completed {
                                if viewModel.filteredJobs.isEmpty {
                                    emptyState
                                } else {
                                    let completed = viewModel.filteredJobs.filter { $0.status.uppercased() == "COMPLETED" }
                                    let cancelled = viewModel.filteredJobs.filter { $0.status.uppercased() == "CANCELLED" }

                                    VStack(alignment: .leading, spacing: 24) {
                                        if !completed.isEmpty {
                                            VStack(alignment: .leading, spacing: 12) {
                                                Text("COMPLETED")
                                                    .scaledFont(size: 10, weight: .bold)
                                                    .foregroundColor(settings.accentColor)
                                                    .tracking(1)
                                                    .padding(.horizontal, 24)
                                                ForEach(completed) { job in
                                                    ManagerJobCard(job: job)
                                                }
                                            }
                                        }
                                        if !cancelled.isEmpty {
                                            VStack(alignment: .leading, spacing: 12) {
                                                Text("CANCELLED")
                                                    .scaledFont(size: 10, weight: .bold)
                                                    .foregroundColor(.red)
                                                    .tracking(1)
                                                    .padding(.horizontal, 24)
                                                ForEach(cancelled) { job in
                                                    ManagerJobCard(job: job)
                                                }
                                            }
                                        }
                                    }
                                }
                            } else {
                                if viewModel.filteredJobs.isEmpty {
                                    emptyState
                                } else {
                                    ForEach(viewModel.filteredJobs) { job in
                                        ManagerJobCard(job: job)
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)

                        // Bottom Stats
                        HStack(spacing: 16) {
                            let completedCount = viewModel.jobs.filter { $0.status.uppercased() == "COMPLETED" }.count
                            let pendingCount = viewModel.jobs.filter { $0.status.uppercased() != "COMPLETED" && $0.status.uppercased() != "CANCELLED" }.count
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
                viewModel.loadJobs(organizationId: user.organizationId, userId: user.id, role: user.role, isOnline: network.isOnline)
                viewModel.startObservingStatusChanges(organizationId: user.organizationId, userId: user.id, role: user.role)
            }
        }
        .onChange(of: network.isOnline) { _, isOnline in
            if let user = appSession.currentUser {
                viewModel.loadJobs(organizationId: user.organizationId, userId: user.id, role: user.role, isOnline: isOnline)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 44))
                .foregroundColor(settings.secondaryText.opacity(0.3))
            Text("No jobs found for this filter")
                .scaledFont(size: 14)
                .foregroundColor(settings.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }


    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

}

private struct ManagerJobCard: View {
    let job: Job
    @Environment(\.managerTabRouter) private var router
    @ObservedObject var settings = AccessibilitySettings.shared

    var body: some View {
        Button(action: {
            HapticManager.shared.playImpact(style: .light)
            router.selectedJobId = job.id
            router.path.append(ManagerScreen.jobDetails)
        }) {
            HStack(spacing: 0) {
                // Left Status Strip
                Rectangle()
                    .fill(statusColor)
                    .frame(width: 6)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Top Row: Status Pill & Time
                    HStack(spacing: 8) {
                        Text(job.status.uppercased())
                            .scaledFont(size: 9, weight: .bold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(statusColor.opacity(0.12))
                            .foregroundColor(statusColor)
                            .cornerRadius(20)
                        
                        if job.isOverdue {
                            Text("OVERDUE")
                                .scaledFont(size: 9, weight: .black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.red.opacity(0.5), lineWidth: 0.5)
                                )
                        }
                        
                        Spacer()
                        
                        Text(timeString(from: job.scheduledAt))
                            .scaledFont(size: 14, weight: .bold)
                            .foregroundColor(job.isOverdue ? .red : settings.secondaryText)
                    }
                    
                    // Title
                    Text(job.title)
                        .scaledFont(size: 18, weight: .bold, design: .rounded)
                        .foregroundColor(settings.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Location Section
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(settings.accentColor.opacity(0.05))
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
            .background(settings.surfaceColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
            )
            .shadow(color: Color.black.opacity(settings.isHighContrast ? 0 : 0.04), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 24)
        }
        .buttonStyle(.plain)
    }

    private var statusColor: Color {
        if job.isUrgent { return .red }
        switch job.status.uppercased() {
        case "COMPLETED": return settings.isHighContrast ? settings.primaryText : .green
        case "IN-PROGRESS": return .blue
        case "HOLD": return .orange
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
