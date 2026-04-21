import SwiftUI

struct ManagerDashboardView: View {
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = DashboardViewModel()
    @ObservedObject private var network = NetworkService.shared
    @ObservedObject private var syncManager = SyncManager.shared
    @Binding var selectedTab: TabItem
    @Environment(\.managerTabRouter) private var router
    @State private var isRefreshing = false
    @State private var showLastSynced = false
    @State private var technicianCount = 0
    @ObservedObject var settings = AccessibilitySettings.shared

    private let localStorage = LocalStorageService.shared
    private let firebase = FirebaseService.shared

    init(selectedTab: Binding<TabItem> = .constant(.dashboard)) {
        _selectedTab = selectedTab
    }
    
    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                BrandHeaderNav(showOnlineStatus: true, isOnline: network.isOnline, isManager: true)
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Header text
                        VStack(alignment: .leading, spacing: 4) {
                            Text(todayString())
                                .scaledFont(size: 12, weight: .bold)
                                .foregroundColor(settings.secondaryText)
                            
                            Text("Good morning, \(appSession.currentUser?.displayName ?? "Marcus")")
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

                        // Total Jobs Today
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TOTAL JOBS TODAY")
                                    .scaledFont(size: 10, weight: .bold)
                                    .foregroundColor(settings.secondaryText)
                                Text("\(viewModel.totalJobsToday)")
                                    .scaledFont(size: 40, weight: .bold, design: .rounded)
                                    .foregroundColor(settings.accentColor)
                            }
                            Spacer()
                            Button(action: {
                                router.currentScreen = .calendar
                                router.selectedTab = .dashboard
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.elevateLightGray)
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.system(size: 20))
                                        .foregroundColor(.black)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(24)
                        .background(settings.surfaceColor)
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                        )
                        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                        
                        // Pending and Urgent
                        HStack(spacing: 16) {
                            // Pending
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PENDING")
                                    .scaledFont(size: 10, weight: .bold)
                                    .foregroundColor(settings.secondaryText)
                                Text("\(pendingJobsCount())")
                                    .scaledFont(size: 28, weight: .bold, design: .rounded)
                                    .foregroundColor(settings.primaryText)
                            }
                             .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(24)
                            .background(settings.surfaceColor)
                            .cornerRadius(24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                            
                            // Urgent
                            VStack(alignment: .leading, spacing: 4) {
                                Text("URGENT")
                                    .scaledFont(size: 10, weight: .bold)
                                    .foregroundColor(.red.opacity(0.8))
                                Text(String(format: "%02d", viewModel.urgentJobsToday))
                                    .scaledFont(size: 28, weight: .bold, design: .rounded)
                                    .foregroundColor(.red)
                            }
                             .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(24)
                            .background(settings.isHighContrast ? Color.black : Color.red.opacity(0.1))
                            .cornerRadius(24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: settings.isHighContrast ? 3 : 0)
                            )
                        }

                        // Technician Availability Map Shortcut
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = .map
                            }
                        }) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "map.fill")
                                            .font(.system(size: 12))
                                        Text("LIVE TRACKING")
                                            .scaledFont(size: 10, weight: .heavy)
                                    }
                                    .foregroundColor(.white.opacity(0.8))
                                    
                                    Text("\(technicianCount) Technicians Active")
                                        .scaledFont(size: 18, weight: .bold, design: .rounded)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                
                                // Mini radar/pulse dot visual
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 48, height: 48)
                                    Circle()
                                        .fill(Color.white.opacity(0.4))
                                        .frame(width: 32, height: 32)
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 12, height: 12)
                                        .shadow(color: .green, radius: 4, x: 0, y: 0)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                             .padding(24)
                            .background(
                                settings.isHighContrast ? AnyView(Color.black) : 
                                AnyView(LinearGradient(gradient: Gradient(colors: [Color.elevateDarkGreen, Color.elevateDarkGreen.opacity(0.85)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            )
                            .cornerRadius(24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: settings.isHighContrast ? 3 : 0)
                            )
                            .shadow(color: settings.isHighContrast ? .clear : Color.elevateDarkGreen.opacity(0.3), radius: 10, x: 0, y: 6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Shortcuts
                        HStack(spacing: 8) {
                            ManagerShortcutItem(title: "CREATE\nJOB", icon: "plus", color: Color.green.opacity(0.1), iconColor: .elevateDarkGreen) {
                                router.currentScreen = .createJob
                                router.selectedTab = .dashboard
                            }
                            ManagerShortcutItem(title: "APPROVE", icon: "checklist", color: Color.elevateLightGray, iconColor: .black) {
                                router.currentScreen = .pendingQuotations
                                router.selectedTab = .dashboard
                            }
                            ManagerShortcutItem(title: "INVENTORY", icon: "shippingbox", color: Color.elevateLightGray, iconColor: .black) {
                                router.currentScreen = .inventoryManager
                                router.selectedTab = .dashboard
                            }
                            ManagerShortcutItem(title: "STATS", icon: "chart.bar.fill", color: Color.elevateLightGray, iconColor: .black) {
                                router.currentScreen = .statistics
                                router.selectedTab = .dashboard
                            }
                        }
                        
                        // Today's Tasks
                        VStack(alignment: .leading, spacing: 16) {
                             HStack {
                                Text("TODAY'S TASKS")
                                    .scaledFont(size: 14, weight: .bold)
                                    .foregroundColor(settings.secondaryText)
                                Spacer()
                                Button(action: {
                                    router.currentScreen = .jobs
                                    router.selectedTab = .jobs
                                }) {
                                    Text("View All")
                                        .scaledFont(size: 12, weight: .bold)
                                        .foregroundColor(settings.accentColor)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            VStack(spacing: 16) {
                                ForEach(viewModel.jobs.filter { Calendar.current.isDateInToday($0.scheduledAt) }.prefix(3), id: \.id) { job in
                                    Button(action: {
                                        router.selectedJobId = job.id
                                        router.currentScreen = .jobDetails
                                        router.selectedTab = .jobs
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
                    let finishSync = {
                        isRefreshing = false
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            showLastSynced = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showLastSynced = false
                            }
                        }
                    }
                    
                    isRefreshing = true
                    if let user = appSession.currentUser {
                        viewModel.loadJobs(organizationId: user.organizationId, userId: user.id, isOnline: network.isOnline) {
                            finishSync()
                        }
                    } else {
                        isRefreshing = false
                    }
                }
                .background(settings.appBackground) // Ensure scroll container matches aesthetic
            }
            .background(settings.appBackground)
            
        }
        .navigationBarHidden(true)
        .speakOnAppear("Welcome to your Manager Dashboard")
        .onAppear {
            if let user = appSession.currentUser {
                viewModel.loadJobs(organizationId: user.organizationId, userId: user.id, isOnline: network.isOnline)
                loadTechnicians(organizationId: user.organizationId)
            }
        }
        .onChange(of: network.isOnline) { _, isOnline in
            if let user = appSession.currentUser {
                viewModel.loadJobs(organizationId: user.organizationId, userId: user.id, isOnline: isOnline)
                loadTechnicians(organizationId: user.organizationId)
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

    private func pendingJobsCount() -> Int {
        viewModel.jobs.filter { $0.status.uppercased() != "COMPLETED" && $0.status.uppercased() != "CANCELLED" }.count
    }

    private func loadTechnicians(organizationId: String) {
        let localTechs = localStorage.fetchUsers(organizationId: organizationId)
            .filter { $0.role.uppercased() == "TECHNICIAN" }
        technicianCount = localTechs.count

        guard network.isOnline else { return }
        firebase.fetchUsers(organizationId: organizationId) { result in
            if case .success(let users) = result {
                self.localStorage.saveUsers(users)
                DispatchQueue.main.async {
                    self.technicianCount = users.filter { $0.role.uppercased() == "TECHNICIAN" }.count
                }
            }
        }
    }

    private func syncStatusText() -> String {
        switch syncManager.status {
        case .idle, .upToDate:
            return lastSyncedText()
        case .syncing:
            return "Syncing"
        case .offline:
            return lastSyncedText()
        case .error:
            return "Sync error"
        }
    }

    private var shouldShowSyncStatus: Bool {
        switch syncManager.status {
        case .upToDate, .idle:
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
        case .idle, .upToDate:
            return .elevateTextGray
        case .syncing:
            return .elevateDarkGreen
        case .offline:
            return .orange
        case .error:
            return .red
        }
    }
}

struct ManagerShortcutItem: View {
    var title: String
    var icon: String
    var color: Color
    var iconColor: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AccessibilitySettings.shared.surfaceColor)
                        .frame(maxWidth: .infinity, minHeight: 72)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AccessibilitySettings.shared.cardStroke, lineWidth: AccessibilitySettings.shared.cardStrokeWidth)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
                    
                    VStack(spacing: 8) {
                        Circle()
                            .fill(AccessibilitySettings.shared.isHighContrast ? Color.black : color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: AccessibilitySettings.shared.isHighContrast ? 2 : 0)
                            )
                            .overlay(
                                Image(systemName: icon)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AccessibilitySettings.shared.isHighContrast ? .white : iconColor)
                            )
                        
                        Text(title)
                            .scaledFont(size: 9, weight: .bold)
                            .foregroundColor(AccessibilitySettings.shared.primaryText)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ManagerDashboardView(selectedTab: .constant(.dashboard))
        .environmentObject(AppSession())
}
