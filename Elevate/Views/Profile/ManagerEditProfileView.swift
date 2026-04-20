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
    @State private var displayName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var isUploadingPhoto = false
    @State private var showDropOrgConfirm = false
    @State private var showDeleteProfileConfirm = false

    enum Field: Hashable { case username, displayName, email, phone, password, confirmPassword }
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
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Edit Profile")
                                .scaledFont(size: 28, weight: .bold, design: .rounded)
                                .foregroundColor(.black)
                            Text("Update your administrative account details and credentials.")
                                .scaledFont(size: 15)
                                .foregroundColor(.elevateTextGray)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        VStack(spacing: 28) {
                            profilePhotoSection

                            VStack(alignment: .leading, spacing: 24) {
                                
                                // IDENTITY SECTION
                                sectionCard(title: "MEMBER IDENTITY", icon: "person.text.rectangle") {
                                    VStack(spacing: 20) {
                                        CustomTextField(
                                            title: "Username",
                                            placeholder: "Manager username",
                                            iconName: "person.fill",
                                            text: $username
                                        )
                                        .focused($focusedField, equals: .username)
                                        .submitLabel(.next)
                                        .onSubmit { focusedField = .displayName }

                                        CustomTextField(
                                            title: "Display Name",
                                            placeholder: "Full Name",
                                            iconName: "textformat",
                                            text: $displayName
                                        )
                                        .focused($focusedField, equals: .displayName)
                                        .submitLabel(.next)
                                        .onSubmit { focusedField = .email }
                                    }
                                }

                                // CONTACT SECTION
                                sectionCard(title: "CONTACT INFORMATION", icon: "envelope.badge") {
                                    VStack(spacing: 20) {
                                        CustomTextField(
                                            title: "Email Address",
                                            placeholder: "Email address",
                                            iconName: "envelope.fill",
                                            text: $email
                                        )
                                        .focused($focusedField, equals: .email)
                                        .submitLabel(.next)
                                        .onSubmit { focusedField = .phone }
                                        .keyboardType(.emailAddress)

                                        CustomTextField(
                                            title: "Phone Number",
                                            placeholder: "Phone Number",
                                            iconName: "phone.fill",
                                            text: $phone
                                        )
                                        .focused($focusedField, equals: .phone)
                                        .submitLabel(.next)
                                        .onSubmit { focusedField = .password }
                                        .keyboardType(.phonePad)
                                    }
                                }

                                // SECURITY SECTION
                                sectionCard(title: "SECURITY ACCESS", icon: "lock.shield") {
                                    VStack(spacing: 20) {
                                        SecureCustomTextField(
                                            title: "New Password",
                                            placeholder: "Leave blank to keep current",
                                            iconName: "lock.fill",
                                            text: $password
                                        )
                                        .focused($focusedField, equals: .password)
                                        .submitLabel(.next)
                                        .onSubmit { focusedField = .confirmPassword }

                                        PasswordRequirementsView(password: password)

                                        SecureCustomTextField(
                                            title: "Confirm Password",
                                            placeholder: "••••••••",
                                            iconName: "lock.shield.fill",
                                            text: $confirmPassword
                                        )
                                        .focused($focusedField, equals: .confirmPassword)
                                        .submitLabel(.done)
                                        .onSubmit { focusedField = nil; saveChanges() }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        VStack(spacing: 16) {
                            PrimaryButton(title: "Save Changes", iconName: "checkmark.circle.fill") {
                                focusedField = nil
                                saveChanges()
                            }
                            
                            if appSession.currentUser?.role == "OWNER" {
                                Button(action: { showDropOrgConfirm = true }) {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                        Text("Delete Organization")
                                    }
                                    .scaledFont(size: 15, weight: .bold)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.red.opacity(0.05))
                                    .cornerRadius(16)
                                }
                            } else {
                                Button(action: { showDeleteProfileConfirm = true }) {
                                    HStack {
                                        Image(systemName: "person.badge.minus.fill")
                                        Text("Delete Account")
                                    }
                                    .scaledFont(size: 15, weight: .bold)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.red.opacity(0.05))
                                    .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
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
                displayName = user.displayName
                email = user.email ?? ""
                phone = user.phone ?? ""
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
        .alert("Wipe Organization", isPresented: $showDropOrgConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Organization", role: .destructive) {
                if let user = appSession.currentUser {
                    viewModel.dropOrganization(organizationId: user.organizationId, appSession: appSession) { success in
                    }
                }
            }
        } message: {
            Text("Are you absolutely sure? This will delete all members, jobs, and organization data permanently.")
        }
        .alert("Delete Profile", isPresented: $showDeleteProfileConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Account", role: .destructive) {
                if let user = appSession.currentUser {
                    viewModel.deleteProfile(userId: user.id, appSession: appSession) { success in
                    }
                }
            }
        } message: {
            Text("Are you absolutely sure you want to delete your profile? This cannot be undone.")
        }
    }

    private func sectionCard<Content: View>(title: String, icon: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.elevateDarkGreen)
                Text(title)
                    .scaledFont(size: 11, weight: .bold)
                    .foregroundColor(.elevateTextGray)
                    .tracking(1)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 20) {
                content()
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)
        }
    }

    private var profilePhotoSection: some View {
        VStack(spacing: 16) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color.elevateLightGray.opacity(0.5))
                        .frame(width: 110, height: 110)
                        .overlay(
                            Group {
                                if let image = profileImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Image(systemName: "person.fill.viewfinder")
                                        .font(.system(size: 40))
                                        .foregroundColor(.elevateDarkGreen.opacity(0.4))
                                }
                            }
                        )
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 8)
                    
                    if isUploadingPhoto {
                        Circle()
                            .fill(Color.elevateDarkGreen)
                            .frame(width: 36, height: 36)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            )
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    } else {
                        Circle()
                            .fill(Color.elevateDarkGreen)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(spacing: 4) {
                Text("Tap to change photo")
                    .scaledFont(size: 14, weight: .bold)
                    .foregroundColor(.elevateDarkGreen)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)
    }

    private func saveChanges() {
        guard let user = appSession.currentUser else { return }
        if !password.isEmpty || !confirmPassword.isEmpty {
            guard password == confirmPassword else {
                viewModel.errorMessage = "Passwords do not match"
                return
            }
            let validation = PasswordValidator.validate(password)
            guard validation.isValid else {
                viewModel.errorMessage = validation.message ?? "Invalid password"
                return
            }
        }
        viewModel.updateProfile(user: user, username: username, displayName: displayName, email: email, phone: phone, password: password.isEmpty ? nil : password) { updated in
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
