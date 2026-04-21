import SwiftUI

struct TechnicianDashboardView: View {
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = DashboardViewModel()
    @ObservedObject private var network = NetworkService.shared
    @ObservedObject private var syncManager = SyncManager.shared
    @Binding var selectedTab: TabItem
    @State private var isRefreshing = false
    @State private var showLastSynced = false
    @State private var navigationJobId: String?
    @ObservedObject var settings = AccessibilitySettings.shared

    init(selectedTab: Binding<TabItem> = .constant(.dashboard)) {
        _selectedTab = selectedTab
    }
    
    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                BrandHeaderNav(showOnlineStatus: true, isOnline: network.isOnline)
                
                // Content Spacer
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Header text
                        VStack(alignment: .leading, spacing: 4) {
                            Text(todayString())
                                .scaledFont(size: 12, weight: .bold)
                                .foregroundColor(settings.secondaryText)
                            
                            Text("Good morning, \(appSession.currentUser?.displayName ?? "Technician")")
                                .scaledFont(size: 24, weight: .bold, design: .rounded)
                                .foregroundColor(settings.primaryText)
                        }

                        if shouldShowSyncStatus {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(syncStatusColor())
                                    .frame(width: 8, height: 8)
                                Text(syncStatusText())
                                    .scaledFont(size: 12, weight: .bold)
                                    .foregroundColor(syncStatusColor())
                                if syncManager.pendingCount > 0 {
                                    Text("Pending: \(syncManager.pendingCount)")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(.elevateTextGray)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Quick Stats
                        HStack(spacing: 16) {
                            StatPill(icon: "calendar", value: "\(technicianJobsTodayCount)", title: "TODAY'S JOBS", isPrimary: true)
                            StatPill(icon: "exclamationmark.triangle", value: "\(technicianUrgentTodayCount)", title: "URGENT", isPrimary: false)
                        }
                        
                        if let urgentMessage = urgentUpdateMessage {
                            Button(action: {
                                if let jobId = urgentJobId {
                                    navigationJobId = jobId
                                }
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("URGENT UPDATE")
                                            .scaledFont(size: 10, weight: .bold)
                                            .foregroundColor(.white.opacity(0.8))
                                        Text(urgentMessage)
                                            .scaledFont(size: 14, weight: .medium)
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .background(settings.isHighContrast ? settings.surfaceColor : Color.elevateDarkGreen)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Shortcuts
                        HStack(spacing: 16) {
                            Button(action: {
                                if let nextJobId = nextJobId {
                                    navigationJobId = nextJobId
                                } else {
                                    selectedTab = .jobs
                                }
                            }) {
                                ShortcutBoxInternal(title: "START JOB", icon: "play.fill")
                            }
                            .buttonStyle(.plain)
                            NavigationLink(destination: TechnicianCalendarView()) {
                                ShortcutBoxInternal(title: "CALENDAR", icon: "calendar")
                            }
                            NavigationLink(destination: TechnicianStatisticsView()) {
                                ShortcutBoxInternal(title: "STATISTICS", icon: "chart.bar")
                            }
                        }
                        
                        // Today's Tasks
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("TODAY'S TASKS")
                                    .scaledFont(size: 14, weight: .bold)
                                    .foregroundColor(settings.secondaryText)
                                Spacer()
                                NavigationLink(destination: JobListView()) {
                                    Text("View All")
                                        .scaledFont(size: 12, weight: .bold)
                                        .foregroundColor(settings.accentColor)
                                }
                            }
                            
                            VStack(spacing: 16) {
                                ForEach(technicianJobs.filter { Calendar.current.isDateInToday($0.scheduledAt) }.prefix(3), id: \.id) { job in
                                    Button(action: {
                                        navigationJobId = job.id
                                    }) {
                                        TaskRow(
                                            time: timeString(from: job.scheduledAt),
                                            ampm: ampmString(from: job.scheduledAt),
                                            title: job.title,
                                            location: job.location,
                                            priority: job.priority.uppercased(),
                                            color: job.priority.uppercased() == "HIGH" || job.priority.uppercased() == "URGENT" ? .red : .blue
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 96)
                }
                .refreshable {
                    if let user = appSession.currentUser {
                        isRefreshing = true
                        viewModel.loadJobs(organizationId: user.organizationId, userId: user.id, isOnline: network.isOnline) {
                            isRefreshing = false
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                showLastSynced = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    showLastSynced = false
                                }
                            }
                        }
                    }
                }
                .background(settings.appBackground)
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: Binding(
            get: { navigationJobId != nil },
            set: { if !$0 { navigationJobId = nil } }
        )) {
            navigationDestination
        }
        .speakOnAppear("Welcome to your Technician Dashboard")
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
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: shouldShowSyncStatus)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: date)
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date()).uppercased()
    }

    private func ampmString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter.string(from: date)
    }

    private func syncStatusText() -> String {
        switch syncManager.status {
        case .idle:
            return "Sync idle"
        case .syncing:
            return "Syncing"
        case .offline:
            return lastSyncedText()
        case .upToDate:
            return lastSyncedText()
        case .error:
            return "Sync error"
        }
    }

    private var shouldShowSyncStatus: Bool {
        switch syncManager.status {
        case .upToDate:
            return isRefreshing || showLastSynced
        default:
            return true
        }
    }

    private func lastSyncedText() -> String {
        guard let lastSyncAt = syncManager.lastSyncAt else {
            return network.isOnline ? "Last synced just now" : "Last synced -"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        let relative = formatter.localizedString(for: lastSyncAt, relativeTo: Date())

        if abs(lastSyncAt.timeIntervalSinceNow) < 60 {
            return "Last synced just now"
        }

        return "Last synced \(relative)"
    }

    private func syncStatusColor() -> Color {
        switch syncManager.status {
        case .idle:
            return .elevateTextGray
        case .syncing:
            return .elevateDarkGreen
        case .offline:
            return .orange
        case .upToDate:
            return .elevateTextGray
        case .error:
            return .red
        }
    }

    private var urgentUpdateMessage: String? {
        let urgentJobs = technicianJobs.filter {
            let priority = $0.priority.uppercased()
            return priority == "HIGH" || priority == "URGENT"
        }

        guard let job = urgentJobs.first else {
            return nil
        }

        let location = job.location.isEmpty ? "your area" : job.location
        return "Urgent job: \(job.title) in \(location)"
    }

    private var urgentJobId: String? {
        technicianJobs.first(where: {
            let priority = $0.priority.uppercased()
            return priority == "HIGH" || priority == "URGENT"
        })?.id
    }

    private var nextJobId: String? {
        let upcoming = technicianJobs.filter {
            let status = $0.status.uppercased()
            return status != "COMPLETED" && status != "CANCELLED"
        }
        return upcoming.sorted { $0.scheduledAt < $1.scheduledAt }.first?.id
    }

    private var technicianJobs: [Job] {
        guard let user = appSession.currentUser else { return [] }
        return viewModel.jobs.filter { $0.assignedUserId == user.id }
    }

    private var navigationDestination: some View {
        Group {
            if let jobId = navigationJobId {
                JobDetailsView(jobId: jobId)
            }
        }
    }

    private var technicianJobsTodayCount: Int {
        technicianJobs.filter { Calendar.current.isDateInToday($0.scheduledAt) }.count
    }

    private var technicianUrgentTodayCount: Int {
        technicianJobs.filter { Calendar.current.isDateInToday($0.scheduledAt) }
            .filter { $0.priority.uppercased() == "HIGH" || $0.priority.uppercased() == "URGENT" }
            .count
    }
}

struct ShortcutBoxInternal: View {
    var title: String
    var icon: String
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AccessibilitySettings.shared.surfaceColor)
                    .frame(height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AccessibilitySettings.shared.cardStroke, lineWidth: AccessibilitySettings.shared.cardStrokeWidth)
                    )
                Image(systemName: icon)
                    .foregroundColor(AccessibilitySettings.shared.accentColor)
                    .font(.system(size: 20))
            }
            Text(title)
                .scaledFont(size: 10, weight: .bold)
                .foregroundColor(AccessibilitySettings.shared.primaryText)
        }
    }
}

struct TaskRow: View {
    var time: String
    var ampm: String
    var title: String
    var location: String
    var priority: String
    var color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 2) {
                Text(time)
                    .scaledFont(size: 14, weight: .bold)
                    .foregroundColor(AccessibilitySettings.shared.primaryText)
                Text(ampm)
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundColor(AccessibilitySettings.shared.secondaryText)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .scaledFont(size: 16, weight: .bold)
                    .foregroundColor(AccessibilitySettings.shared.primaryText)
                Text(location)
                    .scaledFont(size: 12)
                    .foregroundColor(AccessibilitySettings.shared.secondaryText)
                
                Text(priority)
                    .scaledFont(size: 10, weight: .bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AccessibilitySettings.shared.isHighContrast ? AccessibilitySettings.shared.surfaceColor : color.opacity(0.1))
                    .foregroundColor(AccessibilitySettings.shared.isHighContrast ? AccessibilitySettings.shared.primaryText : color)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AccessibilitySettings.shared.cardStroke, lineWidth: AccessibilitySettings.shared.cardStrokeWidth)
                    )
            }
            Spacer()
        }
    }
}

#Preview {
    TechnicianDashboardView(selectedTab: .constant(.dashboard))
        .environmentObject(AppSession())
}
