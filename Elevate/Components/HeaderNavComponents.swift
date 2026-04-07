import SwiftUI

struct NotificationBell: View {
    @EnvironmentObject private var appSession: AppSession
    @State private var unreadCount: Int = 0
    private let localStorage = LocalStorageService.shared
    var isManager: Bool = false
    @Environment(\.managerTabRouter) private var router
    
    var body: some View {
        Group {
            if isManager {
                Button(action: {
                    router.currentScreen = .notifications
                    router.selectedTab = .dashboard
                }) {
                    bellContent
                }
                .buttonStyle(.plain)
            } else {
                NavigationLink(destination: TechnicianNotificationsView()) { bellContent }
            }
        }
        .onAppear {
            refreshUnreadCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: .notificationsDidChange)) { _ in
            refreshUnreadCount()
        }
    }
    
    private var bellContent: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "bell")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.elevateDarkGreen)
            if unreadCount > 0 {
                Text("\(min(unreadCount, 99))")
                    .scaledFont(size: 9, weight: .bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.white, lineWidth: 1.5)
                    )
                    .offset(x: 6, y: -6)
            }
        }
    }

    private func refreshUnreadCount() {
        guard let user = appSession.currentUser else {
            unreadCount = 0
            return
        }
        unreadCount = localStorage.unreadNotificationCount(organizationId: user.organizationId, userId: user.id)
    }
}

struct BrandHeaderNav: View {
    var showOnlineStatus: Bool = false
    var isOnline: Bool = true
    var isManager: Bool = false
    
    var body: some View {
        HStack {
            Text("elevate")
                .scaledFont(size: 24, weight: .black, design: .rounded)
                .foregroundColor(.elevateDarkGreen)
            
            Spacer()
            
            HStack(spacing: 16) {
                if showOnlineStatus {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isOnline ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                        Text(isOnline ? "ONLINE" : "OFFLINE")
                            .scaledFont(size: 11, weight: .bold)
                            .foregroundColor(isOnline ? .green : .red)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.elevateLightGray)
                    .cornerRadius(12)
                }
                NotificationBell(isManager: isManager)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white)
    }
}

struct BackHeaderNav: View {
    @Environment(\.presentationMode) var presentationMode
    var isManager: Bool = false
    var onBack: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Button(action: {
                if let onBack {
                    onBack()
                } else {
                    presentationMode.wrappedValue.dismiss()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                    Text("Back")
                        .scaledFont(size: 16, weight: .bold)
                }
                .foregroundColor(.elevateDarkGreen)
            }
            Spacer()
            NotificationBell(isManager: isManager)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white)
    }
}

enum TabItem {
    case dashboard, jobs, map, profile
}

enum BottomNavMode {
    case tabs
    case links
}


