import SwiftUI

struct ManagerMainTabView: View {
    @StateObject private var router = ManagerTabRouter.shared
    @StateObject private var mapViewModel = MapViewModel()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            Group {
                switch router.selectedTab {
                case .dashboard:
                    ManagerDashboardView(selectedTab: $router.selectedTab)
                case .jobs:
                    ManagerJobListView()
                case .map:
                    ManagerMapView(viewModel: mapViewModel)
                case .profile:
                    ManagerProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationDestination(for: ManagerScreen.self) { screen in
                switch screen {
                case .jobDetails:
                    if let jobId = router.selectedJobId {
                        ManagerJobDetailsView(jobId: jobId)
                    }
                case .jobIssueReport:
                    if let jobId = router.selectedJobId {
                        ManagerJobIssueReportView(jobId: jobId)
                    }
                case .quotationApproval:
                    if let jobId = router.selectedJobId {
                        ManagerQuotationApprovalView(jobId: jobId)
                    }
                case .createJob:
                    ManagerCreateJobView()
                case .calendar:
                    ManagerCalendarView()
                case .statistics:
                    ManagerStatisticsView()
                case .notifications:
                    ManagerNotificationsView()
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
                case .memberDetails:
                    if let memberId = router.selectedMemberId {
                        ManagerMemberDetailView(memberId: memberId)
                    }
                case .pendingQuotations:
                    ManagerPendingQuotationListView()
                case .inventoryManager:
                    ManagerInventoryView()
                default:
                    EmptyView()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            ManagerBottomNav(selectedTab: $router.selectedTab, mode: .tabs) { tab in
                router.selectedTab = tab
                // Clear path when switching tabs to ensure we're at root
                router.path = NavigationPath()
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .padding(.bottom, 8)
        }
        .environment(\.managerTabRouter, router)
    }
}

#Preview {
    ManagerMainTabView()
}
