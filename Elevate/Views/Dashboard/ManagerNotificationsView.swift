import SwiftUI

struct ManagerNotificationsView: View {
    @Environment(\.managerTabRouter) private var router
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = NotificationsViewModel()
    @ObservedObject private var network = NetworkService.shared
    @ObservedObject var settings = AccessibilitySettings.shared
    
    @State private var showResetAlert = false
    @State private var resetTargetId: String? = nil
    @State private var resetTargetName: String = ""
    @State private var newPasswordInput: String = ""
    @State private var showSuccessAlert = false
    @State private var resetMessage = ""
    
    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav(isManager: true, showNotificationBell: false, onBack: {
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
        .alert("Reset Password", isPresented: $showResetAlert) {
            TextField("New Password", text: $newPasswordInput)
            Button("Cancel", role: .cancel) {
                newPasswordInput = ""
                resetTargetId = nil
            }
            Button("Reset") {
                if let userId = resetTargetId, !newPasswordInput.isEmpty {
                    FirebaseService.shared.resetUserPassword(userId: userId, newPassword: newPasswordInput) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success:
                                resetMessage = "Password for \(resetTargetName) has been reset successfully."
                                showSuccessAlert = true
                            case .failure(let error):
                                resetMessage = "Error: \(error.localizedDescription)"
                                showSuccessAlert = true
                            }
                            newPasswordInput = ""
                            resetTargetId = nil
                        }
                    }
                }
            }
        } message: {
            Text("Enter a new temporary password for \(resetTargetName).")
        }
        .alert("Status", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(resetMessage)
        }
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
        guard appSession.currentUser != nil else { return }
        viewModel.markRead(item, isOnline: NetworkService.shared.isOnline)
        
        if item.type.uppercased() == "PASSWORD_RESET" {
            resetTargetId = item.targetId
            // Extract name from body if possible, or just use a generic title
            // Body is usually "[Name] has requested a password reset."
            resetTargetName = item.body.replacingOccurrences(of: " has requested a password reset.", with: "")
            showResetAlert = true
        } else {
            router.handleDeepLink(type: item.type.uppercased(), targetId: item.targetId)
        }
    }
}

#Preview {
    ManagerNotificationsView()
        .environmentObject(AppSession())
}
