import SwiftUI

struct ManagerProfileView: View {
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.managerTabRouter) private var router
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
                            
                            Button(action: {
                                router.currentScreen = .editProfile
                                router.selectedTab = .profile
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.pencil")
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
                        Button(action: {
                            router.currentScreen = .organization
                            router.selectedTab = .profile
                        }) {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("ORGANIZATION DETAILS")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(.elevateTextGray)
                                    Spacer()
                                    HStack(spacing: 8) {
                                        Image(systemName: "building.2")
                                            .foregroundColor(.gray)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.gray)
                                    }
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
                                    HStack(spacing: 8) {
                                        Image(systemName: "person.text.rectangle")
                                            .foregroundColor(.elevateDarkGreen)
                                        Text("ORGANIZATION MANAGER")
                                            .foregroundColor(.elevateDarkGreen)
                                    }
                                    .scaledFont(size: 10, weight: .bold)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.elevateLightGray)
                                    .cornerRadius(10)

                                    Spacer()

                                    Text("MANAGE")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(.elevateDarkGreen)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 10)
                                        .background(Color.elevateLightGray)
                                        .cornerRadius(10)
                                }
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.elevateLightGray, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        
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
                                
                                Button(action: {
                                    router.currentScreen = .accessibility
                                    router.selectedTab = .profile
                                }) {
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
                                .buttonStyle(.plain)
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
                        
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear
                        .frame(height: 120)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            
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
        HapticManager.shared.playImpact(style: .medium)
        withAnimation(.easeOut(duration: 0.3)) {
            appSession.signOut()
        }
    }
}

#Preview {
    ManagerProfileView()
}
