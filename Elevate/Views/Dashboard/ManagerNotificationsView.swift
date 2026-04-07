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
                            NotificationSection(title: "TODAY", items: viewModel.todayItems)
                            NotificationSection(title: "YESTERDAY", items: viewModel.yesterdayItems)
                            NotificationSection(title: "EARLIER", items: viewModel.olderItems)
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
}

#Preview {
    ManagerNotificationsView()
        .environmentObject(AppSession())
}
