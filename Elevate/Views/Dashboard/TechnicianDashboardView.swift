import SwiftUI
import MapKit

struct TechnicianDashboardView: View {
    @EnvironmentObject private var appSession: AppSession
    @Environment(\.technicianTabRouter) private var router
    @StateObject private var viewModel = DashboardViewModel()
    @ObservedObject private var network = NetworkService.shared
    @ObservedObject private var syncManager = SyncManager.shared
    @State private var isRefreshing = false
    @State private var showLastSynced = false
    @ObservedObject var settings = AccessibilitySettings.shared
    @ObservedObject var locationService = LocationService.shared
    @State private var travelTime: String? = nil
    
    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                BrandHeaderNav(showOnlineStatus: true, isOnline: network.isOnline)
                
                // Content Spacer
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        syncStatusSection

                        // Header title for stats
                        Text("MY WORKLOAD")
                            .scaledFont(size: 14, weight: .bold)
                            .foregroundColor(settings.secondaryText)
                            .padding(.top, 8)

                        workloadOverview
                        
                        // Smart Navigation Card
                        SmartNavigationCard(job: upcomingJob, travelTime: travelTime) {
                            if let job = upcomingJob {
                                router.selectedTab = .map
                                router.mapFocusJobId = job.id
                                router.path = NavigationPath()
                            }
                        }

                        urgentUpdateSection
                        shortcutSection
                        tasksSection
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
                        viewModel.loadJobs(organizationId: user.organizationId, userId: user.id, role: user.role, isOnline: network.isOnline) {
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
        .speakOnAppear("Welcome to your Technician Dashboard")
        .onAppear {
            locationService.requestAuthorization()
            if let user = appSession.currentUser {
                viewModel.loadJobs(organizationId: user.organizationId, userId: user.id, role: user.role, isOnline: network.isOnline)
            }
        }
        .onChange(of: network.isOnline) { _, isOnline in
            if let user = appSession.currentUser {
                viewModel.loadJobs(organizationId: user.organizationId, userId: user.id, role: user.role, isOnline: isOnline)
            }
        }
        .onChange(of: upcomingJob) { _, newJob in
            if let job = newJob {
                calculateETA(for: job)
            } else {
                travelTime = nil
            }
        }
        .onChange(of: locationService.authorizationStatus) { _, _ in
            if let job = upcomingJob {
                calculateETA(for: job)
            }
        }
    }

    private func calculateETA(for job: Job) {
        guard let current = locationService.currentLocation,
              let lat = job.siteLatitude,
              let lon = job.siteLongitude,
              (lat != 0 || lon != 0) else {
            print("DEBUG: Missing or invalid (0,0) coordinates for ETA calculation")
            return
        }

        // Reset travelTime before every calculation to show "Calculating..."
        self.travelTime = nil

        let source = CLLocation(latitude: current.latitude, longitude: current.longitude)
        let destination = CLLocation(latitude: lat, longitude: lon)
        let distance = source.distance(from: destination)
        
        // Robustness: If within 500m, skip server calculation and show Nearby
        if distance < 500 {
            print("DEBUG: Job is within 500m (\(Int(distance))m). Showing 'Nearby'.")
            DispatchQueue.main.async {
                self.travelTime = "Nearby"
            }
            return
        }

        let request = MKDirections.Request()
        
        if #available(iOS 26.0, *) {
            request.source = MKMapItem(location: source, address: nil)
            request.destination = MKMapItem(location: destination, address: nil)
        } else {
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: current))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
        }
        
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculateETA { response, error in
            DispatchQueue.main.async {
                if let eta = response?.expectedTravelTime {
                    print("DEBUG: MKDirections successful: \(eta)s")
                    self.updateTravelTime(with: eta, isEstimate: false)
                } else {
                    self.travelTime = "N/A"
                }
            }
        }
    }

    private func updateTravelTime(with seconds: TimeInterval, isEstimate: Bool) {
        if seconds < 60 {
            self.travelTime = "Nearby"
        } else {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .abbreviated
            formatter.allowedUnits = [.hour, .minute]
            let timeString = formatter.string(from: seconds) ?? "Nearby"
            self.travelTime = isEstimate ? "~\(timeString)" : timeString
        }
    }

    private func openInAppMap(job: Job) {
        router.selectedJobId = job.id
        router.selectedTab = .map
    }

    private var upcomingJob: Job? {
        let upcoming = technicianJobs.filter {
            let status = $0.status.uppercased()
            return status != "COMPLETED" && status != "CANCELLED"
        }
        return upcoming.sorted { $0.scheduledAt < $1.scheduledAt }.first
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
            let status = $0.status.uppercased()
            return (priority == "HIGH" || priority == "URGENT") && 
                   (status != "COMPLETED" && status != "CANCELLED")
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
            let status = $0.status.uppercased()
            return (priority == "HIGH" || priority == "URGENT") && 
                   (status != "COMPLETED" && status != "CANCELLED")
        })?.id
    }

    private var nextJobId: String? {
        upcomingJob?.id
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(todayString())
                .scaledFont(size: 12, weight: .bold)
                .foregroundColor(settings.secondaryText)
            
            Text("Good morning, \(appSession.currentUser?.displayName ?? "Technician")")
                .scaledFont(size: 24, weight: .bold, design: .rounded)
                .foregroundColor(settings.primaryText)
        }
    }

    @ViewBuilder
    private var syncStatusSection: some View {
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
    }

    @ViewBuilder
    private var workloadOverview: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Column 1: Today's Pending
                VStack(alignment: .center, spacing: 4) {
                    Text("TODAY")
                        .scaledFont(size: 9, weight: .bold)
                        .foregroundColor(settings.secondaryText)
                    Text("\(technicianPendingTodayCount)")
                        .scaledFont(size: 24, weight: .bold, design: .rounded)
                        .foregroundColor(settings.primaryText)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 32)
                    .background(settings.cardStroke)
                
                // Column 2: Today's Urgent
                VStack(alignment: .center, spacing: 4) {
                    Text("URGENT")
                        .scaledFont(size: 9, weight: .bold)
                        .foregroundColor(settings.isHighContrast ? settings.primaryText : .red.opacity(0.8))
                    Text("\(technicianUrgentTodayCount)")
                        .scaledFont(size: 24, weight: .bold, design: .rounded)
                        .foregroundColor(settings.isHighContrast ? settings.primaryText : .red)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 32)
                    .background(settings.cardStroke)
                
                // Column 3: All Pending
                VStack(alignment: .center, spacing: 4) {
                    Text("TOTAL")
                        .scaledFont(size: 9, weight: .bold)
                        .foregroundColor(settings.secondaryText)
                    Text("\(technicianTotalPendingCount)")
                        .scaledFont(size: 24, weight: .bold, design: .rounded)
                        .foregroundColor(settings.primaryText)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 20)
        .background(settings.surfaceColor)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }

    @ViewBuilder
    private var urgentUpdateSection: some View {
        if let urgentMessage = urgentUpdateMessage {
            Button(action: {
                if let jobId = urgentJobId {
                    router.selectedJobId = jobId
                    router.path.append(TechnicianScreen.jobDetails)
                }
            }) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                            Text("URGENT UPDATE")
                                .scaledFont(size: 10, weight: .heavy)
                        }
                        .foregroundColor(.white.opacity(0.8))
                        
                        Text(urgentMessage)
                            .scaledFont(size: 16, weight: .bold, design: .rounded)
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(24)
                .background(
                    settings.isHighContrast ? AnyView(settings.surfaceColor) : 
                    AnyView(LinearGradient(gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                )
                .shadow(color: settings.isHighContrast ? .clear : Color.red.opacity(0.3), radius: 10, x: 0, y: 6)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var shortcutSection: some View {
        HStack(spacing: 8) {
            TechnicianShortcutItem(title: "START\nJOB", icon: "play.fill", color: Color.green.opacity(0.1), iconColor: .elevateDarkGreen) {
                if let nextJobId = nextJobId {
                    router.selectedJobId = nextJobId
                    router.path.append(TechnicianScreen.jobDetails)
                } else {
                    router.selectedTab = .jobs
                }
            }
            TechnicianShortcutItem(title: "CALENDAR", icon: "calendar", color: Color.elevateLightGray, iconColor: .black) {
                router.path.append(TechnicianScreen.calendar)
            }
            
            TechnicianShortcutItem(title: "STATS", icon: "chart.bar.fill", color: Color.elevateLightGray, iconColor: .black) {
                router.path.append(TechnicianScreen.statistics)
            }
        }
    }

    @ViewBuilder
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("TODAY'S TASKS")
                    .scaledFont(size: 14, weight: .bold)
                    .foregroundColor(settings.secondaryText)
                Spacer()
                NavigationLink(value: TechnicianScreen.jobs) {
                    Text("View All")
                        .scaledFont(size: 12, weight: .bold)
                        .foregroundColor(settings.accentColor)
                }
            }
            
            VStack(spacing: 16) {
                if viewModel.isLoading && technicianJobs.isEmpty {
                    ForEach(0..<3) { _ in
                        SkeletonTaskRow()
                    }
                } else {
                    let jobs = technicianJobs.filter { 
                        let isToday = Calendar.current.isDateInToday($0.scheduledAt)
                        let isOverdue = $0.isOverdue
                        return (isToday || isOverdue) && 
                        $0.status.uppercased() != "COMPLETED" && 
                        $0.status.uppercased() != "CANCELLED" 
                    }.prefix(3)
                    
                    ForEach(jobs, id: \.id) { job in
                        Button(action: {
                            router.selectedJobId = job.id
                            router.path.append(TechnicianScreen.jobDetails)
                        }) {
                            TaskRow(
                                time: timeString(from: job.scheduledAt),
                                ampm: ampmString(from: job.scheduledAt),
                                title: job.title,
                                location: job.location,
                                priority: job.priority.uppercased(),
                                isOverdue: job.isOverdue,
                                color: (job.isOverdue || job.priority.uppercased() == "HIGH" || job.priority.uppercased() == "URGENT") ? .red : .blue
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var technicianJobs: [Job] {
        guard let user = appSession.currentUser else { return [] }
        return viewModel.jobs.filter { $0.assignedUserId == user.id }
    }


    private var technicianPendingTodayCount: Int {
        technicianJobs.filter { 
            let isToday = Calendar.current.isDateInToday($0.scheduledAt)
            let isOverdue = $0.isOverdue
            return (isToday || isOverdue)
        }.filter { 
            let status = $0.status.uppercased()
            return status != "COMPLETED" && status != "CANCELLED" 
        }.count
    }

    private var technicianUrgentTodayCount: Int {
        technicianJobs.filter { 
            let isToday = Calendar.current.isDateInToday($0.scheduledAt)
            let isOverdue = $0.isOverdue
            return (isToday || isOverdue)
        }.filter { 
            let priority = $0.priority.uppercased()
            return priority == "HIGH" || priority == "URGENT"
        }.filter {
            let status = $0.status.uppercased()
            return status != "COMPLETED" && status != "CANCELLED"
        }.count
    }

    private var technicianTotalPendingCount: Int {
        technicianJobs.filter { 
            let status = $0.status.uppercased()
            return status != "COMPLETED" && status != "CANCELLED" 
        }.count
    }
}

struct TechnicianShortcutItem: View {
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
                            .fill(AccessibilitySettings.shared.isHighContrast ? AccessibilitySettings.shared.surfaceColor : color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle().stroke(AccessibilitySettings.shared.primaryText, lineWidth: AccessibilitySettings.shared.isHighContrast ? 1.5 : 0)
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

struct SmartNavigationCard: View {
    var job: Job?
    var travelTime: String?
    var onNavigate: () -> Void
    
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon section
            ZStack {
                Circle()
                    .fill(settings.isHighContrast ? settings.surfaceColor : settings.accentColor.opacity(0.1))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle().stroke(settings.primaryText, lineWidth: settings.isHighContrast ? 1.5 : 0)
                    )
                
                Image(systemName: job == nil ? "checkmark.circle.fill" : "map.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(job == nil ? .green : settings.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let job = job {
                    Text(job.isOverdue ? "OVERDUE JOB" : "NEXT JOB")
                        .scaledFont(size: 10, weight: .heavy)
                        .foregroundColor(job.isOverdue ? .red : settings.secondaryText)
                    
                    Text(job.title)
                        .scaledFont(size: 16, weight: .bold)
                        .foregroundColor(settings.primaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let time = travelTime {
                        Text("\(time) away")
                            .scaledFont(size: 12, weight: .medium)
                            .foregroundColor(job.isOverdue ? .red : settings.accentColor)
                    } else {
                        Text("Calculating ETA...")
                            .scaledFont(size: 12, weight: .medium)
                            .foregroundColor(settings.secondaryText)
                    }
                } else {
                    Text("ALL DONE")
                        .scaledFont(size: 10, weight: .heavy)
                        .foregroundColor(settings.secondaryText)
                    
                    Text("Work day complete")
                        .scaledFont(size: 16, weight: .bold)
                        .foregroundColor(settings.primaryText)
                    
                    Text("You've finished all your tasks for today.")
                        .scaledFont(size: 12, weight: .medium)
                        .foregroundColor(settings.secondaryText)
                }
            }
            
            Spacer()
            
            if let _ = job {
                Button(action: onNavigate) {
                    Image(systemName: "arrow.turn.up.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(settings.accentColor)
                        .cornerRadius(12)
                        .shadow(color: settings.accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(settings.surfaceColor)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
    }
}


#Preview {
    TechnicianDashboardView()
        .environmentObject(AppSession())
}
