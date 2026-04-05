import SwiftUI

struct TechnicianProfileView: View {
    @State private var enableFaceID = true
    @State private var enableNotifications = true
    
    var body: some View {
        ZStack {
            Color.elevateLightGray.opacity(0.3).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BrandHeaderNav(showOnlineStatus: false)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // User Details
                        VStack(spacing: 12) {
                            Circle()
                                .fill(Color.elevateDarkGreen)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 44))
                                        .foregroundColor(.white)
                                )
                            
                            Text("Marcus V.")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                        }
                        .padding(.top, 32)
                        
                        // ORGANIZATION DETAILS CARD
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("ORGANIZATION DETAILS")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.elevateTextGray)
                                Spacer()
                                Image(systemName: "building.2")
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Skyline Corp")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.elevateDarkGreen)
                                Text("ORG-1024-SV")
                                    .font(.system(size: 12))
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
                        
                        // APP SETTINGS
                        VStack(alignment: .leading, spacing: 12) {
                            Text("APP SETTINGS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.elevateTextGray)
                            
                            VStack(spacing: 0) {
                                AppSettingToggleRow(title: "Enable Face ID", subtitle: "Secure biometric login", icon: "faceid", isOn: $enableFaceID)
                                Divider().padding(.leading, 64)
                                AppSettingToggleRow(title: "Notification Preferences", subtitle: "Manage push alerts", icon: "bell", isOn: $enableNotifications)
                                Divider().padding(.leading, 64)
                                
                                NavigationLink(destination: TechnicianAccessibilityView()) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "figure.arms.open")
                                            .font(.system(size: 20))
                                            .foregroundColor(.elevateDarkGreen)
                                            .frame(width: 32, height: 32)
                                            .background(Color.elevateLightGray)
                                            .cornerRadius(6)
                                        
                                        Text("Accessibility Settings")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.black)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 20)
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
                        }
                        
                        // LOGOUT
                        Button(action: {}) {
                            HStack(spacing: 8) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("LOGOUT")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.3), lineWidth: 1))
                            .background(Color.white)
                            .cornerRadius(8)
                        }
                        
                        Spacer().frame(height: 120) // Custom tab bar space
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            // Bottom Navbar Floating
            ReusableBottomNav(selectedTab: .constant(.profile))
        }
        .navigationBarHidden(true)
    }
}

struct AppSettingToggleRow: View {
    var title: String
    var subtitle: String
    var icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.gray)
                .frame(width: 32, height: 32)
                .background(Color.elevateLightGray)
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(.elevateDarkGreen)
                .labelsHidden()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }
}

#Preview {
    TechnicianProfileView()
}
