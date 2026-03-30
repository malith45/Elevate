import SwiftUI

enum Tab {
    case home, jobs, map, profile
}

struct CustomBottomNavBar: View {
    @Binding var selectedTab: Tab
    
    // Extracted Colors based on screenshot
    let bgColor = Color(red: 45/255, green: 55/255, blue: 72/255).opacity(0.8) // Glassy capsule bg
    let unselectedColor = Color(red: 25/255, green: 35/255, blue: 50/255) // Much darker icon color for unselected
    let activeTextColor = Color(red: 14/255, green: 165/255, blue: 233/255) // Bright Light Blue (#0EA5E9)
    let activeBgColor = Color(red: 37/255, green: 99/255, blue: 235/255).opacity(0.3) // Pale blue square background
    let borderColor = Color.white.opacity(0.2) // Subtle light border

    var body: some View {
        HStack {
            NavBarItem(icon: "house.fill", title: "Home", tab: .home, selectedTab: $selectedTab, activeTextColor: activeTextColor, activeBgColor: activeBgColor, unselectedColor: unselectedColor)
            Spacer()
            // using a combination of wrench to match the screenshot icon
            NavBarItem(icon: "wrench.and.screwdriver.fill", title: "Jobs", tab: .jobs, selectedTab: $selectedTab, activeTextColor: activeTextColor, activeBgColor: activeBgColor, unselectedColor: unselectedColor)
            Spacer()
            NavBarItem(icon: "map.fill", title: "Map", tab: .map, selectedTab: $selectedTab, activeTextColor: activeTextColor, activeBgColor: activeBgColor, unselectedColor: unselectedColor)
            Spacer()
            NavBarItem(icon: "person.fill", title: "Profile", tab: .profile, selectedTab: $selectedTab, activeTextColor: activeTextColor, activeBgColor: activeBgColor, unselectedColor: unselectedColor)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 35)
                .fill(bgColor)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 35)
                .stroke(borderColor, lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

struct NavBarItem: View {
    let icon: String
    let title: String
    let tab: Tab
    @Binding var selectedTab: Tab
    
    let activeTextColor: Color
    let activeBgColor: Color
    let unselectedColor: Color
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 26))
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(selectedTab == tab ? activeTextColor : unselectedColor)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                selectedTab == tab ? 
                RoundedRectangle(cornerRadius: 18).fill(activeBgColor) : 
                RoundedRectangle(cornerRadius: 18).fill(Color.clear)
            )
        }
    }
}

#Preview {
    ZStack {
        Color(red: 15/255, green: 23/255, blue: 42/255).ignoresSafeArea()
        CustomBottomNavBar(selectedTab: .constant(.home))
    }
}
