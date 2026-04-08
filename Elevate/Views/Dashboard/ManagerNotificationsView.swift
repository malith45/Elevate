import SwiftUI

struct ManagerNotificationsView: View {
    @Environment(\.managerTabRouter) private var router
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = NotificationsViewModel()
    
    var body: some View {
        ZStack {
            Color.elevateLightGray.opacity(0.3).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav(isManager: true, onBack: {
                    router.currentScreen = .dashboard
                    router.selectedTab = .dashboard
                })
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Header
                        HStack {
                            Text("Notifications")
                                .scaledFont(size: 32, weight: .bold, design: .rounded)
                            Spacer()
                            Button("Clear All") {
                                clearNotifications()
                            }
                            .scaledFont(size: 14, weight: .bold)
                            .foregroundColor(.elevateDarkGreen)
                        }
                        .padding(.horizontal, 24)
                        
                        if viewModel.notifications.isEmpty {
                            EmptyStateCard()
                        } else {
                            NotificationSection(title: "TODAY", items: viewModel.todayItems, onTap: handleTap)
                            NotificationSection(title: "YESTERDAY", items: viewModel.yesterdayItems, onTap: handleTap)
                            NotificationSection(title: "EARLIER", items: viewModel.olderItems, onTap: handleTap)
                        }
                        
                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 16)
                }
            }
            
        }
        .navigationBarHidden(true)
        .onAppear {
            loadNotifications()
        }
    }

    private func loadNotifications() {
        guard let user = appSession.currentUser else { return }
        let isOnline = NetworkService.shared.isOnline
        viewModel.load(organizationId: user.organizationId, userId: user.id, isOnline: isOnline)
    }

    private func clearNotifications() {
        guard let user = appSession.currentUser else { return }
        viewModel.clearAll(organizationId: user.organizationId, userId: user.id)
    }

    private func handleTap(_ item: NotificationItem) {
        guard appSession.currentUser != nil else { return }
        viewModel.markRead(item, isOnline: NetworkService.shared.isOnline)
        guard let targetId = item.targetId else { return }

        router.selectedJobId = targetId
        router.selectedTab = .jobs

        let type = item.type.uppercased()
        if type.contains("ISSUE") {
            router.currentScreen = .jobIssueReport
        } else if type.contains("QUOTATION") || type.contains("QUOTE") {
            router.currentScreen = .quotationApproval
        } else {
            router.currentScreen = .jobDetails
        }
    }
}

#Preview {
    ManagerNotificationsView()
        .environmentObject(AppSession())
}
