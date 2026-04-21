import SwiftUI
import MapKit

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
    @ObservedObject var locationService = LocationService.shared
    @State private var travelTime: String? = nil

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

                        // Header title for stats
                        Text("MY WORKLOAD")
                            .scaledFont(size: 14, weight: .bold)
                            .foregroundColor(settings.secondaryText)
                            .padding(.top, 8)

                        // Unified Overview Card
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
                        
                        // Smart Navigation Card
                        SmartNavigationCard(job: upcomingJob, travelTime: travelTime) {
                            if let job = upcomingJob {
                                openInAppleMaps(job: job)
                            }
                        }

                        if let urgentMessage = urgentUpdateMessage {
                            Button(action: {
                                if let jobId = urgentJobId {
                                    navigationJobId = jobId
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
                        
                        // Shortcuts
                        HStack(spacing: 8) {
                            TechnicianShortcutItem(title: "START\nJOB", icon: "play.fill", color: Color.green.opacity(0.1), iconColor: .elevateDarkGreen) {
                                if let nextJobId = nextJobId {
                                    navigationJobId = nextJobId
                                } else {
                                    selectedTab = .jobs
                                }
                            }
                            TechnicianShortcutItem(title: "CALENDAR", icon: "calendar", color: Color.elevateLightGray, iconColor: .black) {
                                // Manual navigation handle if needed, but here we use the link pattern usually
                            }
                            .overlay(
                                NavigationLink(destination: TechnicianCalendarView()) {
                                    EmptyView()
                                }.opacity(0)
                            )
                            
                            TechnicianShortcutItem(title: "STATS", icon: "chart.bar.fill", color: Color.elevateLightGray, iconColor: .black) {
                                // Manual navigation
                            }
                            .overlay(
                                NavigationLink(destination: TechnicianStatisticsView()) {
                                    EmptyView()
                                }.opacity(0)
                            )
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
            locationService.requestAuthorization()
            if let user = appSession.currentUser {
                viewModel.loadJobs(organizationId: user.organizationId, userId: user.id, isOnline: network.isOnline)
            }
        }
        .onChange(of: network.isOnline) { _, isOnline in
            if let user = appSession.currentUser {
                viewModel.loadJobs(organizationId: user.organizationId, userId: user.id, isOnline: isOnline)
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
                    // FALLBACK: If routing fails (expected in Sri Lanka), use distance-based estimate
                    // Average speed in Colombo traffic (approx 25 km/h = 6.94 m/s)
                    let averageSpeedMps: Double = 6.94 
                    let estimatedTime = distance / averageSpeedMps
                    
                    print("DEBUG: MKDirections failed (\(error?.localizedDescription ?? "No route")). Using Estimate: \(Int(estimatedTime))s")
                    self.updateTravelTime(with: estimatedTime, isEstimate: true)
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

    private func openInAppleMaps(job: Job) {
        guard let lat = job.siteLatitude, let lon = job.siteLongitude else {
            let address = job.location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "http://maps.apple.com/?address=\(address)") {
                UIApplication.shared.open(url)
            }
            return
        }

        let sourceItem: MKMapItem
        let destinationItem: MKMapItem
        
        // Use hardcoded Colombo start point to ensure external app works correctly
        let startCoord = CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)
        let destCoord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
        if #available(iOS 26.0, *) {
            sourceItem = MKMapItem(location: CLLocation(latitude: startCoord.latitude, longitude: startCoord.longitude), address: nil)
            destinationItem = MKMapItem(location: CLLocation(latitude: destCoord.latitude, longitude: destCoord.longitude), address: nil)
        } else {
            sourceItem = MKMapItem(placemark: MKPlacemark(coordinate: startCoord))
            destinationItem = MKMapItem(placemark: MKPlacemark(coordinate: destCoord))
        }
        
        sourceItem.name = "My Location"
        destinationItem.name = job.title
        
        MKMapItem.openMaps(with: [sourceItem, destinationItem], launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
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
        upcomingJob?.id
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

    private var technicianPendingTodayCount: Int {
        technicianJobs.filter { Calendar.current.isDateInToday($0.scheduledAt) }
            .filter { 
                let status = $0.status.uppercased()
                return status != "COMPLETED" && status != "CANCELLED" 
            }.count
    }

    private var technicianUrgentTodayCount: Int {
        technicianJobs.filter { Calendar.current.isDateInToday($0.scheduledAt) }
            .filter { 
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
                    Text("NEXT JOB")
                        .scaledFont(size: 10, weight: .heavy)
                        .foregroundColor(settings.secondaryText)
                    
                    Text(job.title)
                        .scaledFont(size: 16, weight: .bold)
                        .foregroundColor(settings.primaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let time = travelTime {
                        Text("\(time) away")
                            .scaledFont(size: 12, weight: .medium)
                            .foregroundColor(settings.accentColor)
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
                    Text("Navigate")
                        .scaledFont(size: 12, weight: .bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(settings.accentColor)
                        .cornerRadius(20)
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
        .padding(16)
        .background(AccessibilitySettings.shared.surfaceColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AccessibilitySettings.shared.cardStroke, lineWidth: AccessibilitySettings.shared.cardStrokeWidth)
        )
    }
}

#Preview {
    TechnicianDashboardView(selectedTab: .constant(.dashboard))
        .environmentObject(AppSession())
}

#Preview {
    TechnicianDashboardView(selectedTab: .constant(.dashboard))
        .environmentObject(AppSession())
}
