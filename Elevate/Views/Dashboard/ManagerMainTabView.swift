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
                    NavigationStack { JobListView() }
                case .map:
                    NavigationStack { TechnicianMapView(viewModel: mapViewModel) }
                case .profile:
                    NavigationStack { TechnicianProfileView() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom Navbar Floating
            ReusableBottomNav(selectedTab: $selectedTab, mode: .tabs)
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    ManagerMainTabView()
}
