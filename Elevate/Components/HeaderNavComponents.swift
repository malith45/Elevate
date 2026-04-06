import SwiftUI

struct NotificationBell: View {
    @EnvironmentObject private var appSession: AppSession
    @State private var unreadCount: Int = 0
    private let localStorage = LocalStorageService.shared
    
    var body: some View {
        NavigationLink(destination: TechnicianNotificationsView()) {
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
        .onAppear {
            refreshUnreadCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: .notificationsDidChange)) { _ in
            refreshUnreadCount()
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
                            .fill(isOnline ? Color.elevateDarkGreen : Color.red)
                            .frame(width: 6, height: 6)
                        Text(isOnline ? "ONLINE" : "OFFLINE")
                            .scaledFont(size: 11, weight: .bold)
                            .foregroundColor(isOnline ? .elevateDarkGreen : .red)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.elevateLightGray)
                    .cornerRadius(12)
                }
                NotificationBell()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white)
    }
}

struct BackHeaderNav: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        HStack {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                    Text("Back")
                        .scaledFont(size: 16, weight: .bold)
                }
                .foregroundColor(.elevateDarkGreen)
            }
            Spacer()
            NotificationBell()
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

struct ReusableBottomNav: View {
    @Binding var selectedTab: TabItem
    var mode: BottomNavMode = .links
    
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                HStack(spacing: 0) {
                    GlobalTabBarButton(tab: .dashboard, title: "DASHBOARD", iconName: "square.grid.2x2", selectedTab: $selectedTab, mode: mode)
                    GlobalTabBarButton(tab: .jobs, title: "JOBS", iconName: "briefcase", selectedTab: $selectedTab, mode: mode)
                    GlobalTabBarButton(tab: .map, title: "MAP", iconName: "map", selectedTab: $selectedTab, mode: mode)
                    GlobalTabBarButton(tab: .profile, title: "PROFILE", iconName: "person", selectedTab: $selectedTab, mode: mode)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .background(Color.white.opacity(0.8))
                .cornerRadius(40)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

struct GlobalTabBarButton: View {
    var tab: TabItem
    var title: String
    var iconName: String
    @Binding var selectedTab: TabItem
    var mode: BottomNavMode
    
    var isSelected: Bool {
        selectedTab == tab
    }
    
    var body: some View {
        switch mode {
        case .tabs:
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = tab
                }
            }) {
                buttonContent
            }
        case .links:
            NavigationLink(destination: destinationView(for: tab)) {
                buttonContent
            }
            .simultaneousGesture(TapGesture().onEnded {
                selectedTab = tab
            })
        }
    }

    private var buttonContent: some View {
        Group {
            if isSelected {
                VStack(spacing: 4) {
                    Image(systemName: iconName)
                        .font(.system(size: 20))
                        .environment(\.symbolVariants, .fill)
                    Text(title)
                        .scaledFont(size: 10, weight: .bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.elevateDarkGreen)
                .cornerRadius(30)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: iconName)
                        .font(.system(size: 20))
                    Text(title)
                        .scaledFont(size: 10, weight: .bold)
                }
                .foregroundColor(.elevateTextGray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
    }

    private func destinationView(for tab: TabItem) -> AnyView {
        switch tab {
        case .dashboard:
            return AnyView(TechnicianDashboardView(selectedTab: .constant(.dashboard)))
        case .jobs:
            return AnyView(JobListView())
        case .map:
            return AnyView(TechnicianMapView())
        case .profile:
            return AnyView(TechnicianProfileView())
        }
    }
}
