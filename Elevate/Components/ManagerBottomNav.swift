import SwiftUI

struct ManagerBottomNav: View {
    @Binding var selectedTab: TabItem
    var mode: BottomNavMode = .links
    var onSelect: ((TabItem) -> Void)? = nil
    @Namespace private var selectionNamespace
    
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                ManagerTabBarButton(tab: .dashboard, title: "HOME", iconName: "house", selectedTab: $selectedTab, mode: mode, selectionNamespace: selectionNamespace, onSelect: onSelect)
                ManagerTabBarButton(tab: .jobs, title: "JOBS", iconName: "briefcase", selectedTab: $selectedTab, mode: mode, selectionNamespace: selectionNamespace, onSelect: onSelect)
                ManagerTabBarButton(tab: .map, title: "MAP", iconName: "map", selectedTab: $selectedTab, mode: mode, selectionNamespace: selectionNamespace, onSelect: onSelect)
                ManagerTabBarButton(tab: .profile, title: "PROFILE", iconName: "person", selectedTab: $selectedTab, mode: mode, selectionNamespace: selectionNamespace, onSelect: onSelect)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(0.75))
            .overlay(
                RoundedRectangle(cornerRadius: 40)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    .blur(radius: 0.5)
            )
            .cornerRadius(40)
            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: selectedTab)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
}

struct ManagerTabBarButton: View {
    var tab: TabItem
    var title: String
    var iconName: String
    @Binding var selectedTab: TabItem
    var mode: BottomNavMode
    var selectionNamespace: Namespace.ID
    var onSelect: ((TabItem) -> Void)? = nil
    
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
                onSelect?(tab)
            }) {
                buttonContent
            }
        case .links:
            if isSelected {
                buttonContent
            } else {
                NavigationLink(destination: destinationView(for: tab)) {
                    buttonContent
                }
                .simultaneousGesture(TapGesture().onEnded {
                    selectedTab = tab
                    onSelect?(tab)
                })
            }
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
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.elevateDarkGreen)
                        .matchedGeometryEffect(id: "tabHighlight", in: selectionNamespace)
                        .shadow(color: Color.elevateDarkGreen.opacity(0.35), radius: 12, x: 0, y: 6)
                )
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
                .scaleEffect(0.98)
            }
        }
    }

    private func destinationView(for tab: TabItem) -> AnyView {
        switch tab {
        case .dashboard:
            return AnyView(ManagerDashboardView(selectedTab: .constant(.dashboard)))
        case .jobs:
            return AnyView(ManagerJobListView())
        case .map:
            return AnyView(ManagerMapView(viewModel: MapViewModel()))
        case .profile:
            return AnyView(ManagerProfileView())
        }
    }
}
