import SwiftUI
import PhotosUI
import UIKit

struct TechnicianProfileView: View {
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = ProfileViewModel()
    @AppStorage("biometricLoginEnabled") private var biometricLoginEnabled = true
    @AppStorage("pushNotificationsEnabled") private var pushNotificationsEnabled = true
    @State private var showLogoutConfirmation = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
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
                            if let user = appSession.currentUser {
                                ProfilePhotoView(userId: user.id, size: 100)
                            } else {
                                Circle()
                                    .fill(Color.elevateDarkGreen)
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 44))
                                            .foregroundColor(.white)
                                    )
                                    .clipShape(Circle())
                            }
                            
                            Text(displayName)
                                .scaledFont(size: 28, weight: .bold, design: .rounded)

                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.pencil")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("CHANGE PHOTO")
                                }
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.elevateDarkGreen)
                                .cornerRadius(16)
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
                                
                                NavigationLink(destination: TechnicianAccessibilityView()) {
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
                        
                    }
                    .padding(.horizontal, 24)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 96)
                }
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
        .onChange(of: selectedPhotoItem) { _, newValue in
            guard let newValue, let user = appSession.currentUser else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let _ = UIImage(data: data) {
                    ProfilePhotoService.shared.uploadProfilePhoto(data: data, userId: user.id) { result in
                        if case .success(let url) = result {
                            ProfileImageStore.shared.saveRemoteUrl(url, for: user.id)
                        }
                        _ = ProfileImageStore.shared.saveImage(data, for: user.id)
                    }
                }
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
        return "Technician"
    }

    private var organizationName: String {
        if !viewModel.organizationName.isEmpty {
            return viewModel.organizationName
        }
        if let user = appSession.currentUser {
            return user.organizationId
        }
        return ""
    }

    private var organizationCode: String {
        if !viewModel.organizationCode.isEmpty {
            return viewModel.organizationCode
        }
        if let user = appSession.currentUser {
            return user.organizationId
        }
        return ""
    }

    private var profileImage: UIImage? {
        guard let user = appSession.currentUser else { return nil }
        return ProfileImageStore.shared.loadImage(for: user.id)
    }

    private func loadProfile() {
        guard let user = appSession.currentUser else { return }
        viewModel.load(userId: user.id)
    }

    private func signOut() {
        appSession.signOut()
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
                    .scaledFont(size: 16, weight: .semibold)
                Text(subtitle)
                    .scaledFont(size: 12)
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
