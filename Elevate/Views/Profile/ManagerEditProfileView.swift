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
    @State private var isUploadingPhoto = false

    enum Field: Hashable { case username, password, confirmPassword }
    @FocusState private var focusedField: Field?

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
                            .focused($focusedField, equals: .username)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }

                            SecureCustomTextField(
                                title: "NEW PASSWORD",
                                placeholder: "Leave blank to keep current",
                                iconName: "lock",
                                text: $password
                            )
                            .focused($focusedField, equals: .password)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .confirmPassword }

                            SecureCustomTextField(
                                title: "CONFIRM PASSWORD",
                                placeholder: "••••••••",
                                iconName: "lock.fill",
                                text: $confirmPassword
                            )
                            .focused($focusedField, equals: .confirmPassword)
                            .submitLabel(.done)
                            .onSubmit { focusedField = nil; saveChanges() }
                        }
                        .padding(.horizontal, 24)

                        PrimaryButton(title: "Save Changes", iconName: "checkmark") {
                            focusedField = nil
                            saveChanges()
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollDismissesKeyboard(.interactively)
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
            isUploadingPhoto = true
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    let uploadData = image.jpegData(compressionQuality: 0.85) ?? data
                    DispatchQueue.main.async {
                        self.profileImage = image
                    }
                    _ = ProfileImageStore.shared.saveImage(uploadData, for: user.id)
                    NotificationCenter.default.post(
                        name: .profilePhotoDidUpdate,
                        object: nil,
                        userInfo: ["userId": user.id]
                    )
                    ProfilePhotoService.shared.uploadProfilePhoto(data: uploadData, userId: user.id) { result in
                        DispatchQueue.main.async {
                            self.isUploadingPhoto = false
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
                } else {
                    DispatchQueue.main.async { self.isUploadingPhoto = false }
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
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.elevateDarkGreen)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Group {
                            if let image = profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            }
                        }
                    )
                    .clipShape(Circle())

                if isUploadingPhoto {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(width: 24, height: 24)
                        .background(Color.elevateDarkGreen)
                        .clipShape(Circle())
                        .offset(x: 4, y: 4)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("PROFILE PHOTO")
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundColor(.elevateTextGray)
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.badge.plus")
                        Text(isUploadingPhoto ? "Uploading…" : "Change Photo")
                    }
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundColor(.elevateDarkGreen)
                }
                .buttonStyle(.plain)
                .disabled(isUploadingPhoto)
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
            guard password.count >= 6 else {
                viewModel.errorMessage = "Password must be at least 6 characters."
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
