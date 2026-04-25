import SwiftUI
import UIKit

struct ManagerProfileView: View {
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject var settings = AccessibilitySettings.shared
    @Environment(\.managerTabRouter) private var router
    @AppStorage("biometricLoginEnabled") private var biometricLoginEnabled = true
    @AppStorage("pushNotificationsEnabled") private var pushNotificationsEnabled = true
    @State private var showLogoutConfirmation = false
    
    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BrandHeaderNav(showOnlineStatus: false, isManager: true)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // USER HEADER SECTION
                        VStack(spacing: 16) {
                            ZStack(alignment: .bottomTrailing) {
                                if let user = appSession.currentUser {
                                    ProfilePhotoView(userId: user.id, size: 110)
                                        .overlay(Circle().stroke(settings.surfaceColor, lineWidth: 3))
                                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                }
                                
                                Button(action: {
                                    HapticManager.shared.playImpact(style: .light)
                                    router.path.append(ManagerScreen.editProfile)
                                }) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 34, height: 34)
                                        .background(settings.accentColor)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(settings.surfaceColor, lineWidth: 2))
                                }
                                .offset(x: 2, y: 2)
                            }
                            
                            VStack(spacing: 4) {
                                Text(displayName)
                                    .scaledFont(size: 24, weight: .bold, design: .rounded)
                                    .foregroundColor(settings.primaryText)
                                
                                Text(appSession.currentUser?.role.uppercased() ?? "MANAGER")
                                    .scaledFont(size: 10, weight: .black)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(settings.accentColor)
                                    .cornerRadius(6)
                                    .tracking(1)
                            }
                        }
                        .padding(.top, 24)
                        
                        // ADMINISTRATIVE HUB (Organization Hub)
                        Button(action: {
                            HapticManager.shared.playImpact(style: .medium)
                            router.path.append(ManagerScreen.organization)
                        }) {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Text("ADMINISTRATIVE HUB")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(settings.secondaryText)
                                        .tracking(1)
                                    Spacer()
                                    Image(systemName: "shield.lefthalf.filled")
                                        .font(.system(size: 12))
                                        .foregroundColor(settings.accentColor)
                                }
                                .padding(.horizontal, 4)
                                
                                HStack(spacing: 16) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(settings.accentColor.opacity(0.05))
                                            .frame(width: 50, height: 50)
                                        Image(systemName: "building.2.fill")
                                            .foregroundColor(settings.accentColor)
                                            .font(.system(size: 20))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(organizationName)
                                            .scaledFont(size: 16, weight: .bold)
                                            .foregroundColor(settings.primaryText)
                                        Text("MANAGE ORGANIZATION")
                                            .scaledFont(size: 10, weight: .bold)
                                            .foregroundColor(settings.accentColor)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(settings.accentColor.opacity(0.8))
                                }
                                .padding(16)
                                .background(settings.surfaceColor)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                )
                                .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Organization: \(organizationName)")
                        .accessibilityHint("Double tap to view organization details")
                        
                        // PREFERENCES & SETTINGS
                        VStack(alignment: .leading, spacing: 16) {
                            Text("ADMINISTRATIVE SETTINGS")
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(settings.secondaryText)
                                .tracking(1)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                AppSettingToggleRow(title: "Face ID Authentication", subtitle: "Secure your sessions", icon: "faceid", isOn: $biometricLoginEnabled)
                                Divider().padding(.leading, 64).background(settings.cardStroke)
                                AppSettingToggleRow(title: "Push Notifications", subtitle: "Manage push alerts", icon: "bell.fill", isOn: $pushNotificationsEnabled)
                                Divider().padding(.leading, 64).background(settings.cardStroke)
                                
                                Button(action: {
                                    HapticManager.shared.playImpact(style: .light)
                                    router.path.append(ManagerScreen.accessibility)
                                }) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(settings.accentColor.opacity(0.05))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "waveform.circle.fill")
                                                .foregroundColor(settings.accentColor)
                                                .font(.system(size: 16, weight: .bold))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Accessibility")
                                                .scaledFont(size: 15, weight: .semibold)
                                                .foregroundColor(settings.primaryText)
                                            Text("Optimize for your needs")
                                                .scaledFont(size: 11)
                                                .foregroundColor(settings.secondaryText)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(settings.accentColor.opacity(0.6))
                                    }
                                    .padding(16)
                                }
                                .buttonStyle(.plain)
                            }
                            .background(settings.surfaceColor)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                            )
                            .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
                        }
                        
                        // ACCOUNT ACTIONS
                        VStack(spacing: 16) {
                            Button(action: { 
                                HapticManager.shared.playImpact(style: .medium)
                                showLogoutConfirmation = true 
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Log Out")
                                        .scaledFont(size: 15, weight: .bold)
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.red.opacity(0.05))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.red.opacity(0.1), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.top, 8)
                        
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
        .speakOnAppear("Manager Profile and Administrative Settings")
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
        .onChange(of: pushNotificationsEnabled) { _, newValue in
            guard let user = appSession.currentUser else { return }
            
            // Update User model preference
            viewModel.updateNotificationPreference(userId: user.id, enabled: newValue)
            
            if newValue {
                if let token = UserDefaults.standard.string(forKey: "fcmToken") {
                    FirebaseService.shared.saveFcmToken(userId: user.id, token: token)
                }
            } else {
                FirebaseService.shared.saveFcmToken(userId: user.id, token: "")
            }
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
        return "Unknown organization"
    }

    private var organizationCode: String {
        if !viewModel.organizationCode.isEmpty {
            return viewModel.organizationCode
        }
        if let user = appSession.currentUser {
            return user.organizationId
        }
        return "Unknown code"
    }

    private func loadProfile() {
        guard let user = appSession.currentUser else { return }
        viewModel.load(userId: user.id)
        pushNotificationsEnabled = user.notificationsEnabled
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
