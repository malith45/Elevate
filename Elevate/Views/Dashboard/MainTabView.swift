import SwiftUI



struct MainTabView: View {
    @State private var selectedTab: TabItem = .dashboard
    
    var body: some View {
        ZStack {
            // Main content based on selected tab
            Group {
                switch selectedTab {
                case .dashboard:
                    NavigationStack { TechnicianDashboardView() }
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
            ReusableBottomNav(selectedTab: $selectedTab)
        }
        .navigationBarHidden(true)
    }
}



#Preview {
    MainTabView()
}
