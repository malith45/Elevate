import SwiftUI

struct TechnicianNotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.technicianTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = NotificationsViewModel()
    @ObservedObject private var network = NetworkService.shared
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav(showNotificationBell: false, onBack: {
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
                            HStack(spacing: 16) {
                                Button("Mark All") {
                                    if let user = appSession.currentUser {
                                        viewModel.markAllRead(organizationId: user.organizationId, userId: user.id)
                                    }
                                }
                                .scaledFont(size: 14, weight: .bold)
                                .foregroundColor(settings.accentColor)
                                
                                Button("Clear All") {
                                    clearNotifications()
                                }
                                .scaledFont(size: 14, weight: .bold)
                                .foregroundColor(settings.accentColor)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        if viewModel.notifications.isEmpty {
                            EmptyStateView(title: "No notifications yet", message: "Updates about jobs, approvals, and inventory will show up here.")
                        } else {
                            NotificationSection(title: "TODAY", items: viewModel.todayItems) { item in
                                handleTap(item)
                            }
                            NotificationSection(title: "YESTERDAY", items: viewModel.yesterdayItems) { item in
                                handleTap(item)
                            }
                            NotificationSection(title: "EARLIER", items: viewModel.olderItems) { item in
                                handleTap(item)
                            }
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
        viewModel.markRead(item, isOnline: NetworkService.shared.isOnline)
        router.handleDeepLink(type: item.type.uppercased(), targetId: item.targetId)
    }
}



#Preview {
    TechnicianNotificationsView()
        .environmentObject(AppSession())
}
