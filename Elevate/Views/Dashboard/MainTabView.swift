import SwiftUI



struct MainTabView: View {
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var router = TechnicianTabRouter.shared
    @StateObject private var mapViewModel = MapViewModel()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            Group {
                switch router.selectedTab {
                case .dashboard:
                    TechnicianDashboardView()
                case .jobs:
                    JobListView()
                case .map:
                    TechnicianMapView(viewModel: mapViewModel)
                case .profile:
                    TechnicianProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationDestination(for: TechnicianScreen.self) { screen in
                destinationView(for: screen)
            }
        }
        .environment(\.technicianTabRouter, router)
        .safeAreaInset(edge: .bottom) {
            TechnicianBottomNav(selectedTab: $router.selectedTab, mode: .tabs) { tab in
                router.selectedTab = tab
                router.path = NavigationPath() // Standard reset on tab switch if needed
            }
                .ignoresSafeArea(.keyboard)
                .padding(.bottom, 8)
        }
    }
    
    @ViewBuilder
    private func destinationView(for screen: TechnicianScreen) -> some View {
        switch screen {
        case .dashboard: TechnicianDashboardView()
        case .jobs: JobListView()
        case .map: TechnicianMapView(viewModel: mapViewModel)
        case .profile: TechnicianProfileView()
        case .calendar: TechnicianCalendarView()
        case .statistics: TechnicianStatisticsView()
        case .notifications: TechnicianNotificationsView()
        case .jobDetails: 
            if let jobId = router.selectedJobId {
                JobDetailsView(jobId: jobId)
            }
        case .jobIssueReport:
            if let jobId = router.selectedJobId {
                JobIssueReportView(jobId: jobId)
            }
        case .quotationStatus:
            if let jobId = router.selectedJobId {
                QuotationStatusView(jobId: jobId)
            }
        case .inventory:
            if let jobId = router.selectedJobId {
                InventoryView(jobId: jobId)
            }
        case .accessibility: TechnicianAccessibilityView()
        case .profilePhoto: 
            if let user = appSession.currentUser {
                ProfilePhotoView(userId: user.id, size: 200)
            }
        }
    }
}



#Preview {
    MainTabView()
}
