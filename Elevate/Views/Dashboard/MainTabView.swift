import SwiftUI



struct MainTabView: View {
    @State private var selectedTab: TabItem = .dashboard
    @StateObject private var mapViewModel = MapViewModel()
    @State private var navResetId = UUID()
    
    var body: some View {
        NavigationStack {
            Group {
                switch selectedTab {
                case .dashboard:
                    TechnicianDashboardView(selectedTab: $selectedTab)
                case .jobs:
                    JobListView()
                case .map:
                    TechnicianMapView(viewModel: mapViewModel)
                case .profile:
                    TechnicianProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .id(navResetId)
        .safeAreaInset(edge: .bottom) {
            TechnicianBottomNav(selectedTab: $selectedTab, mode: .tabs) { tab in
                selectedTab = tab
                navResetId = UUID()
            }
                .ignoresSafeArea(.keyboard)
                .padding(.bottom, 8) // Add small buffer for home indicator
        }
    }
}



#Preview {
    MainTabView()
}
