import SwiftUI

struct ManagerProfileView: View {
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = ProfileViewModel()
    @AppStorage("biometricLoginEnabled") private var biometricLoginEnabled = true
    @AppStorage("pushNotificationsEnabled") private var pushNotificationsEnabled = true
    @State private var showLogoutConfirmation = false
    
    var body: some View {
        ZStack {
            Color.elevateLightGray.opacity(0.3).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BrandHeaderNav(showOnlineStatus: false, isManager: true)
                
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
                            
                            Text(displayName)
                                .scaledFont(size: 28, weight: .bold, design: .rounded)
                            
                            Button(action: { /* Edit Profile */ }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 10, weight: .black))
                                    Text("EDIT PROFILE")
                                }
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.elevateDarkGreen)
                                .cornerRadius(20)
                            }
                        }
                        .padding(.top, 32)
                        
                        // ORGANIZATION DETAILS CARD
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("ORGANIZATION DETAILS")
                                    .scaledFont(size: 10, weight: .bold)
                                    .foregroundColor(.elevateTextGray)
                                Spacer()
                                Image(systemName: "building.2")
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(organizationName)
                                    .scaledFont(size: 18, weight: .bold)
                                    .foregroundColor(.elevateDarkGreen)
                                Text(organizationCode)
                                    .scaledFont(size: 12)
                            }
                            
                            Divider().padding(.vertical, 4)
                            
                            HStack {
                                Spacer()
                                HStack(spacing: 8) {
                                    Image(systemName: "person.text.rectangle")
                                    Text("ORGANIZATION MANAGER")
                                }
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(Color(red: 25/255, green: 99/255, blue: 150/255))
                                .padding(.vertical, 12)
                                Spacer()
                            }
                            .background(Color(red: 25/255, green: 99/255, blue: 150/255).opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
                        
                        // APP SETTINGS
                        VStack(alignment: .leading, spacing: 12) {
                            Text("APP SETTINGS")
                                .scaledFont(size: 12, weight: .bold)
                                .foregroundColor(.elevateTextGray)
                            
                            VStack(spacing: 0) {
                                AppSettingToggleRow(title: "Enable Face ID", subtitle: "Secure biometric login", icon: "faceid", isOn: $biometricLoginEnabled)
                                Divider().padding(.leading, 64)
                                AppSettingToggleRow(title: "Notification Preferences", subtitle: "Manage push alerts", icon: "bell", isOn: $pushNotificationsEnabled)
                                Divider().padding(.leading, 64)
                                
                                NavigationLink(destination: ManagerAccessibilityView()) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "figure.arms.open")
                                            .font(.system(size: 20))
                                            .foregroundColor(.elevateDarkGreen)
                                            .frame(width: 32, height: 32)
                                            .background(Color.elevateLightGray)
                                            .cornerRadius(6)
                                        
                                        Text("Accessibility Settings")
                                            .scaledFont(size: 16, weight: .semibold)
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
                        Button(action: { showLogoutConfirmation = true }) {
                            Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                                .scaledFont(size: 16, weight: .semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .tint(.red)
                        
                        Spacer().frame(height: 120) // Custom tab bar space
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            // Bottom Navbar Floating
            ReusableBottomNav(selectedTab: .constant(.profile), isManager: true)
        }
        .navigationBarHidden(true)
        .alert("Log out?", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) {
                signOut()
            }
        } message: {
            Text("You will need to sign in again to access your account.")
        }
        .onAppear {
            loadProfile()
        }
    }

    private var displayName: String {
        if let user = viewModel.user {
            return user.displayName.isEmpty ? user.username : user.displayName
        }
        if let user = appSession.currentUser {
            return user.displayName.isEmpty ? user.username : user.displayName
        }
        return "Manager"
    }

    private var organizationName: String {
        if !viewModel.organizationName.isEmpty {
            return viewModel.organizationName
        }
        if let user = appSession.currentUser {
            return user.organizationId
        }
        return "Skyline Corp" // Dummy placeholder for mock review
    }

    private var organizationCode: String {
        if !viewModel.organizationCode.isEmpty {
            return viewModel.organizationCode
        }
        if let user = appSession.currentUser {
            return user.organizationId
        }
        return "ORG-1024-SV" // Dummy placeholder for mock review
    }

    private func loadProfile() {
        guard let user = appSession.currentUser else { return }
        viewModel.load(userId: user.id)
    }

    private func signOut() {
        appSession.signOut()
    }
}

#Preview {
    ManagerProfileView()
}
