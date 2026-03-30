import SwiftUI

struct HomeDashboardView: View {
    @State private var selectedTab: Tab = .home
    @State private var showAlerts: Bool = false
    
    let bgColor = Color(red: 15/255, green: 23/255, blue: 42/255) // #0F172A

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            // Dashboard Main Page
            if !showAlerts {
                VStack(spacing: 0) {
                    if selectedTab == .home {
                        // Top Bar Layout
                        HStack {
                            Spacer()
                            
                            // Notification Icon top right
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showAlerts = true
                                }
                            }) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "bell.fill")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                    
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 2, y: -2)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                        
                        Spacer()
                    } else if selectedTab == .profile {
                        ProfileView()
                    } else {
                        Spacer() // Placeholders for .jobs and .map
                    }
                }
                .transition(.opacity)
            } else {
                // Alerts Page
                AlertsView(showAlerts: $showAlerts)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
            
            // Bottom Navigation Bar anchored to bottom
            VStack {
                Spacer()
                CustomBottomNavBar(selectedTab: $selectedTab)
                    .padding(.bottom, 10)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    HomeDashboardView()
}
