import SwiftUI
import PhotosUI
import UIKit

struct ManagerEditProfileView: View {
    @Environment(\.managerTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = ManagerEditProfileViewModel()
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImage: UIImage?

    var body: some View {
        ZStack {
            Color.elevateLightGray.opacity(0.3).ignoresSafeArea()

            VStack(spacing: 0) {
                BackHeaderNav(isManager: true, onBack: {
                    router.currentScreen = .profile
                    router.selectedTab = .profile
                })
                .background(Color.white)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Edit Profile")
                                .scaledFont(size: 22, weight: .bold, design: .rounded)
                            Text("Update your account details")
                                .scaledFont(size: 12)
                                .foregroundColor(.elevateTextGray)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)

                        VStack(spacing: 16) {
                            profilePhotoCard

                            CustomTextField(
                                title: "USERNAME",
                                placeholder: "Manager username",
                                iconName: "person",
                                text: $username
                            )

                            SecureCustomTextField(
                                title: "PASSWORD",
                                placeholder: "••••••••",
                                iconName: "lock",
                                text: $password
                            )

                            SecureCustomTextField(
                                title: "CONFIRM PASSWORD",
                                placeholder: "••••••••",
                                iconName: "lock",
                                text: $confirmPassword
                            )
                        }
                        .padding(.horizontal, 24)

                        PrimaryButton(title: "Save Changes", iconName: "checkmark") {
                            saveChanges()
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if let user = appSession.currentUser {
                username = user.username
                profileImage = ProfileImageStore.shared.loadImage(for: user.id)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            guard let newValue, let user = appSession.currentUser else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.profileImage = image
                    }
                    ProfilePhotoService.shared.uploadProfilePhoto(data: data, userId: user.id) { result in
                        if case .success(let url) = result {
                            ProfileImageStore.shared.saveRemoteUrl(url, for: user.id)
                        }
                        _ = ProfileImageStore.shared.saveImage(data, for: user.id)
                    }
                }
            }
        }
        .alert("Profile", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var profilePhotoCard: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.elevateDarkGreen)
                .frame(width: 64, height: 64)
                .overlay(
                    Group {
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                )
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text("PROFILE PHOTO")
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundColor(.elevateTextGray)
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.pencil")
                        Text("Change Photo")
                    }
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundColor(.elevateDarkGreen)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
    }

    private func saveChanges() {
        guard let user = appSession.currentUser else { return }
        if !password.isEmpty || !confirmPassword.isEmpty {
            guard password == confirmPassword else {
                viewModel.errorMessage = "Passwords do not match."
                return
            }
        }

        viewModel.updateProfile(user: user, username: username, password: password.isEmpty ? nil : password) { updated in
            if let updated = updated {
                appSession.updateCurrentUser(updated)
                router.currentScreen = .profile
                router.selectedTab = .profile
            }
        }
    }
}

#Preview {
    ManagerEditProfileView()
        .environmentObject(AppSession())
}
