import SwiftUI

struct ManagerMainTabView: View {
    @State private var selectedTab: TabItem = .dashboard
    @StateObject private var mapViewModel = MapViewModel()
    
    var body: some View {
        ZStack {
            // Main content based on selected tab
            Group {
                switch selectedTab {
                case .dashboard:
                    NavigationStack { ManagerDashboardView(selectedTab: $selectedTab) }
                case .jobs:
                    NavigationStack { Text("Manager Job List View") }
                case .map:
                    NavigationStack { ManagerMapView(viewModel: mapViewModel) }
                case .profile:
                    NavigationStack { ManagerProfileView() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom Navbar Floating
            ReusableBottomNav(selectedTab: $selectedTab, mode: .tabs, isManager: true)
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    ManagerMainTabView()
}
