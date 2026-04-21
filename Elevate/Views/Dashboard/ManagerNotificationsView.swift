import SwiftUI

struct ManagerNotificationsView: View {
    @Environment(\.managerTabRouter) private var router
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = NotificationsViewModel()
    @ObservedObject private var network = NetworkService.shared
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav(isManager: true, onBack: {
                    dismiss()
                })
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Header
                        HStack {
                            Text("Notifications")
                                .scaledFont(size: 32, weight: .bold, design: .rounded)
                                .foregroundColor(settings.primaryText)
                            Spacer()
                            Button("Clear All") {
                                clearNotifications()
                            }
                            .scaledFont(size: 14, weight: .bold)
                            .foregroundColor(settings.accentColor)
                        }
                        .padding(.horizontal, 24)
                        
                        if viewModel.notifications.isEmpty {
                            EmptyStateView(title: "No notifications yet", message: "Updates about jobs, approvals, and inventory will show up here.")
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
        .onChange(of: network.isOnline) { _, _ in
            loadNotifications()
        }
        .onReceive(NotificationCenter.default.publisher(for: .notificationsDidChange)) { _ in
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
            router.path.append(ManagerScreen.jobIssueReport)
        } else if type.contains("QUOTATION") || type.contains("QUOTE") {
            router.path.append(ManagerScreen.quotationApproval)
        } else {
            router.path.append(ManagerScreen.jobDetails)
        }
    }
}

#Preview {
    ManagerNotificationsView()
        .environmentObject(AppSession())
}
