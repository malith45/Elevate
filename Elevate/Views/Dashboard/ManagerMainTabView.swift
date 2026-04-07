import SwiftUI

struct ManagerMainTabView: View {
    @StateObject private var router = ManagerTabRouter.shared
    @StateObject private var mapViewModel = MapViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch router.currentScreen {
                case .dashboard:
                    ManagerDashboardView(selectedTab: $router.selectedTab)
                case .calendar:
                    ManagerCalendarView()
                case .statistics:
                    ManagerStatisticsView()
                case .notifications:
                    ManagerNotificationsView()
                case .jobs:
                    ManagerJobListView()
                case .map:
                    ManagerMapView(viewModel: mapViewModel)
                case .profile:
                    ManagerProfileView()
                case .accessibility:
                    ManagerAccessibilityView()
                case .organization:
                    ManagerOrganizationView()
                case .members:
                    ManagerMembersView()
                case .editProfile:
                    ManagerEditProfileView()
                case .addMember:
                    ManagerAddMemberView()
                case .jobDetails:
                    if let jobId = router.selectedJobId {
                        ManagerJobDetailsView(jobId: jobId)
                    } else {
                        ManagerJobListView()
                    }
                case .jobIssueReport:
                    if let jobId = router.selectedJobId {
                        ManagerJobIssueReportView(jobId: jobId)
                    } else {
                        ManagerJobListView()
                    }
                case .inventoryManager:
                    ManagerInventoryView()
                case .createJob:
                    ManagerCreateJobView()
                }
            }
            .environment(\.managerTabRouter, router)
            .onChange(of: router.selectedTab) { _, _ in
                switch router.selectedTab {
                case .dashboard:
                    router.currentScreen = .dashboard
                case .jobs:
                    router.currentScreen = .jobs
                case .map:
                    router.currentScreen = .map
                case .profile:
                    router.currentScreen = .profile
                }
            }

            ManagerBottomNav(selectedTab: $router.selectedTab, mode: .tabs)
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .padding(.bottom, 8) // Buffer for home indicator
                .zIndex(1)
        }
    }
}

#Preview {
    ManagerMainTabView()
}
