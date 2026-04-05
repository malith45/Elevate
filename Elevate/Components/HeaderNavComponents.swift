import SwiftUI

struct NotificationBell: View {
    var hasUnread: Bool = true
    
    var body: some View {
        NavigationLink(destination: TechnicianNotificationsView()) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.elevateDarkGreen)
                if hasUnread {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: -2)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                }
            }
        }
    }
}

struct BrandHeaderNav: View {
    var showOnlineStatus: Bool = false
    
    var body: some View {
        HStack {
            Text("elevate")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.elevateDarkGreen)
            
            Spacer()
            
            HStack(spacing: 16) {
                if showOnlineStatus {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.elevateDarkGreen)
                            .frame(width: 6, height: 6)
                        Text("ONLINE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.elevateDarkGreen)
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
                        .font(.system(size: 16, weight: .bold))
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

struct ReusableBottomNav: View {
    @Binding var selectedTab: TabItem
    
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                HStack(spacing: 0) {
                    GlobalTabBarButton(tab: .dashboard, title: "DASHBOARD", iconName: "square.grid.2x2", selectedTab: $selectedTab)
                    GlobalTabBarButton(tab: .jobs, title: "JOBS", iconName: "briefcase", selectedTab: $selectedTab)
                    GlobalTabBarButton(tab: .map, title: "MAP", iconName: "map", selectedTab: $selectedTab)
                    GlobalTabBarButton(tab: .profile, title: "PROFILE", iconName: "person", selectedTab: $selectedTab)
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
    
    var isSelected: Bool {
        selectedTab == tab
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        }) {
            if isSelected {
                VStack(spacing: 4) {
                    Image(systemName: iconName)
                        .font(.system(size: 20))
                        .environment(\.symbolVariants, .fill)
                    Text(title)
                        .font(.system(size: 10, weight: .bold))
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
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.elevateTextGray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
    }
}
