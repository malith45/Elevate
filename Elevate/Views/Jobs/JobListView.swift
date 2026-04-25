import SwiftUI
import MapKit
import CoreLocation

struct JobListView: View {
    @EnvironmentObject private var appSession: AppSession
    @Environment(\.technicianTabRouter) private var router
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
                                            JobCard(job: job)
                                        }
                                    }
                                }
                                
                                if !future.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("UPCOMING JOBS")
                                            .scaledFont(size: 10, weight: .bold)
                                            .foregroundColor(settings.accentColor)
                                            .tracking(1)
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
                                } else if viewModel.selectedFilter == .completed {
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
                                                    JobCard(job: job)
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
                                                    JobCard(job: job)
                                                }
                                            }
                                        }
                                    }
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
                            StatPill(icon: "clock", value: "\(viewModel.jobs.filter { $0.status.uppercased() != "COMPLETED" && $0.status.uppercased() != "CANCELLED" }.count)", title: "PENDING JOBS", isPrimary: false)
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
                .background(isSelected ? (settings.isHighContrast ? settings.accentColor.opacity(0.1) : settings.surfaceColor) : Color.clear)
                .cornerRadius(6)
                .shadow(color: isSelected && !settings.isHighContrast ? Color.black.opacity(0.05) : Color.clear, radius: 2, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? settings.cardStroke : Color.clear, lineWidth: settings.cardStrokeWidth)
                )
        }
    }
}

struct JobCard: View {
    var job: Job
    @Environment(\.technicianTabRouter) private var router
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        Button(action: {
            HapticManager.shared.playImpact(style: .light)
            router.selectedJobId = job.id
            router.path.append(TechnicianScreen.jobDetails)
        }) {
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
                    
                    // Action Row
                    HStack(spacing: 10) {
                        HStack {
                            Text("Open Details")
                                .scaledFont(size: 15, weight: .bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(settings.accentColor)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            HapticManager.shared.playImpact(style: .medium)
                            openMaps()
                        }) {
                            Image(systemName: "arrow.turn.up.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(settings.primaryText)
                                .frame(width: 48, height: 48)
                                .background(settings.secondaryText.opacity(0.05))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
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
    
    private func openMaps() {
        router.selectedTab = .map
        router.mapFocusJobId = job.id
        router.path = NavigationPath()
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
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(settings.isHighContrast ? Color.white.opacity(0.1) : (isPrimary ? Color.white.opacity(0.1) : settings.accentColor.opacity(0.05)))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(settings.isHighContrast ? .white : (isPrimary ? .white : settings.accentColor))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .scaledFont(size: 28, weight: .bold, design: .rounded)
                    .foregroundColor(settings.isHighContrast ? .white : (isPrimary ? .white : settings.primaryText))
                Text(title)
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundColor(settings.isHighContrast ? .white : (isPrimary ? .white.opacity(0.8) : settings.secondaryText))
                    .tracking(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(settings.isHighContrast ? settings.surfaceColor : (isPrimary ? settings.accentColor : settings.surfaceColor))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    JobListView()
        .environmentObject(AppSession())
}
