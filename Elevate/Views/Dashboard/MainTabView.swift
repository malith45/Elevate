import SwiftUI



struct MainTabView: View {
    @State private var selectedTab: TabItem = .dashboard
    
    var body: some View {
        ZStack {
            // Main content based on selected tab
            Group {
                switch selectedTab {
                case .dashboard:
                    NavigationStack { TechnicianDashboardView(selectedTab: $selectedTab) }
                case .jobs:
                    NavigationStack { JobListView() }
                case .map:
                    NavigationStack { TechnicianMapView() }
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
    MainTabView()
}
