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
                        
                        // USER HEADER SECTION
                        VStack(spacing: 16) {
                            ZStack(alignment: .bottomTrailing) {
                                if let user = appSession.currentUser {
                                    ProfilePhotoView(userId: user.id, size: 110)
                                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                }
                                
                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 34, height: 34)
                                        .background(Color.elevateDarkGreen)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                }
                                .offset(x: 2, y: 2)
                            }
                            
                            VStack(spacing: 4) {
                                Text(displayName)
                                    .scaledFont(size: 24, weight: .bold, design: .rounded)
                                
                                Text(appSession.currentUser?.role.uppercased() ?? "TECHNICIAN")
                                    .scaledFont(size: 10, weight: .black)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.elevateDarkGreen)
                                    .cornerRadius(6)
                                    .tracking(1)
                            }
                        }
                        .padding(.top, 24)
                        
                        // ORGANIZATION IDENTITY (Badge Style)
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("IDENTITY")
                                    .scaledFont(size: 10, weight: .bold)
                                    .foregroundColor(.elevateTextGray)
                                    .tracking(1)
                                Spacer()
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.elevateDarkGreen.opacity(0.6))
                            }
                            .padding(.horizontal, 4)
                            
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.elevateDarkGreen.opacity(0.05))
                                        .frame(width: 50, height: 50)
                                    Image(systemName: "building.2")
                                        .foregroundColor(.elevateDarkGreen)
                                        .font(.system(size: 20))
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(organizationName)
                                        .scaledFont(size: 16, weight: .bold)
                                        .foregroundColor(.black)
                                    Text(organizationCode)
                                        .scaledFont(size: 12, weight: .semibold, design: .monospaced)
                                        .foregroundColor(.elevateTextGray)
                                }
                                
                                Spacer()
                                
                                Text("ACTIVE")
                                    .scaledFont(size: 8, weight: .bold)
                                    .foregroundColor(.elevateDarkGreen)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.elevateDarkGreen.opacity(0.1))
                                    .cornerRadius(6)
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
                        }
                        
                        // PREFERENCES & SETTINGS
                        VStack(alignment: .leading, spacing: 16) {
                            Text("PREFERENCES")
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(.elevateTextGray)
                                .tracking(1)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                AppSettingToggleRow(title: "Face ID Authentication", subtitle: "Secure your sessions", icon: "faceid", isOn: $biometricLoginEnabled)
                                Divider().padding(.leading, 64)
                                AppSettingToggleRow(title: "Push Notifications", subtitle: "Stay updated on new jobs", icon: "bell.fill", isOn: $pushNotificationsEnabled)
                                Divider().padding(.leading, 64)
                                
                                NavigationLink(destination: TechnicianAccessibilityView()) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.elevateDarkGreen.opacity(0.05))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "figure.arms.open")
                                                .foregroundColor(.elevateDarkGreen)
                                                .font(.system(size: 16, weight: .bold))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Accessibility")
                                                .scaledFont(size: 15, weight: .semibold)
                                                .foregroundColor(.black)
                                            Text("Optimize for your needs")
                                                .scaledFont(size: 11)
                                                .foregroundColor(.elevateTextGray)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.elevateLightGray)
                                    }
                                    .padding(16)
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
                        }
                        
                        // ACCOUNT ACTIONS
                        VStack(spacing: 16) {
                            Button(action: { showLogoutConfirmation = true }) {
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
                            }
                        }
                        .padding(.top, 8)
                        
                    }
                    .padding(.horizontal, 24)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 96)
                }
            }
            
        }
        .navigationBarHidden(true)
        .speakOnAppear("Technician Profile and Settings")
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
                   let image = UIImage(data: data) {
                    let uploadData = image.jpegData(compressionQuality: 0.85) ?? data
                    // Save locally first
                    _ = ProfileImageStore.shared.saveImage(uploadData, for: user.id)
                    // Notify ProfilePhotoView to refresh
                    NotificationCenter.default.post(
                        name: .profilePhotoDidUpdate,
                        object: nil,
                        userInfo: ["userId": user.id]
                    )
                    ProfilePhotoService.shared.uploadProfilePhoto(data: uploadData, userId: user.id) { result in
                        DispatchQueue.main.async {
                            if case .success(let url) = result {
                                ProfileImageStore.shared.saveRemoteUrl(url, for: user.id)
                                NotificationCenter.default.post(
                                    name: .profilePhotoDidUpdate,
                                    object: nil,
                                    userInfo: ["userId": user.id]
                                )
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: pushNotificationsEnabled) { _, newValue in
            guard let user = appSession.currentUser else { return }
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
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.elevateDarkGreen.opacity(0.05))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(.elevateDarkGreen)
                    .font(.system(size: 16, weight: .bold))
            }
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .scaledFont(size: 15, weight: .semibold)
                Text(subtitle)
                    .scaledFont(size: 11)
                    .foregroundColor(.elevateTextGray)
            }
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(Color.elevateDarkGreen)
                .labelsHidden()
        }
        .padding(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint(subtitle)
    }
}

#Preview {
    TechnicianProfileView()
}
