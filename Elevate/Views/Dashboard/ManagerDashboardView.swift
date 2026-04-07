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

    init(selectedTab: Binding<TabItem> = .constant(.dashboard)) {
        _selectedTab = selectedTab
    }
    
    var body: some View {
        ZStack {
            Color.elevateLightGray.opacity(0.1).ignoresSafeArea() // very light bg
            
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
                                .foregroundColor(.elevateTextGray)
                            
                            Text("Good morning, \(appSession.currentUser?.displayName ?? "Marcus")")
                                .scaledFont(size: 24, weight: .bold, design: .rounded)
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
                                    .foregroundColor(.elevateTextGray)
                                Text("28")
                                    .scaledFont(size: 40, weight: .bold, design: .rounded)
                                    .foregroundColor(.elevateDarkGreen)
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
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                        
                        // Pending and Urgent
                        HStack(spacing: 16) {
                            // Pending
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PENDING")
                                    .scaledFont(size: 10, weight: .bold)
                                    .foregroundColor(.elevateTextGray)
                                Text("14")
                                    .scaledFont(size: 28, weight: .bold, design: .rounded)
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(24)
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                            
                            // Urgent
                            VStack(alignment: .leading, spacing: 4) {
                                Text("URGENT")
                                    .scaledFont(size: 10, weight: .bold)
                                    .foregroundColor(.red.opacity(0.8))
                                Text("03")
                                    .scaledFont(size: 28, weight: .bold, design: .rounded)
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(24)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(24)
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
                                    
                                    Text("12 Technicians Active")
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
                                LinearGradient(gradient: Gradient(colors: [Color.elevateDarkGreen, Color.elevateDarkGreen.opacity(0.85)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .cornerRadius(24)
                            .shadow(color: Color.elevateDarkGreen.opacity(0.3), radius: 10, x: 0, y: 6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Shortcuts
                        HStack(spacing: 8) {
                            ManagerShortcutItem(title: "CREATE\nJOB", icon: "plus", color: Color.green.opacity(0.1), iconColor: .elevateDarkGreen) {
                                router.currentScreen = .createJob
                                router.selectedTab = .dashboard
                            }
                            ManagerShortcutItem(title: "APPROVE", icon: "checklist", color: Color.elevateLightGray, iconColor: .black) {
                                router.currentScreen = .jobs
                                router.selectedTab = .jobs
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
                                    .foregroundColor(.elevateTextGray)
                                Spacer()
                                Button(action: {
                                    router.currentScreen = .jobs
                                    router.selectedTab = .jobs
                                }) {
                                    Text("View All")
                                        .scaledFont(size: 12, weight: .bold)
                                        .foregroundColor(.elevateDarkGreen)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            VStack(spacing: 16) {
                                ForEach(viewModel.jobs.filter { Calendar.current.isDateInToday($0.scheduledAt) }.prefix(3), id: \.id) { job in
                                    TaskRow(
                                        time: timeString(from: job.scheduledAt),
                                        ampm: ampmString(from: job.scheduledAt),
                                        title: job.title,
                                        location: job.location,
                                        priority: job.priority.uppercased(),
                                        color: job.priority.uppercased() == "HIGH" || job.priority.uppercased() == "URGENT" ? .red : .blue
                                    )
                                }
                            }
                        }
                        
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
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
                        // Mock sync for testing without login
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            finishSync()
                        }
                    }
                }
                .background(Color.white) // Ensure scroll container matches aesthetic
            }
            .background(Color.white)
            
        }
        .navigationBarHidden(true)
        .onAppear {
            if let user = appSession.currentUser {
                viewModel.loadJobs(organizationId: user.organizationId, userId: user.id, isOnline: network.isOnline)
            } else {
                // Trigger an initial fake sync for testing without login
                isRefreshing = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
        if network.isOnline {
            return "Last synced now"
        }
        return "Last synced 4m ago"
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
                        .fill(Color.white)
                        .frame(maxWidth: .infinity, minHeight: 72)
                        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
                    
                    VStack(spacing: 8) {
                        Circle()
                            .fill(color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: icon)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(iconColor)
                            )
                        
                        Text(title)
                            .scaledFont(size: 9, weight: .bold)
                            .foregroundColor(.black)
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
