import SwiftUI
import PhotosUI
import UIKit

struct ManagerAddMemberView: View {
    @Environment(\.managerTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = ManagerAddMemberViewModel()
    @State private var selectedRole = "Technician"
    @State private var username = ""
    @State private var displayName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var memberPhotoData: Data?

    private let roles = ["Technician", "Manager"]

    var body: some View {
        ZStack {
            Color.elevateLightGray.opacity(0.3).ignoresSafeArea()

            VStack(spacing: 0) {
                BackHeaderNav(isManager: true, onBack: {
                    router.currentScreen = .members
                    router.selectedTab = .profile
                })
                .background(Color.white)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Team Member")
                                .scaledFont(size: 28, weight: .bold, design: .rounded)
                                .foregroundColor(.black)
                            Text("Provision a new technician or manager account with role-specific credentials.")
                                .scaledFont(size: 15)
                                .foregroundColor(.elevateTextGray)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        VStack(spacing: 28) {
                            profilePhotoCard

                            VStack(alignment: .leading, spacing: 24) {
                                rolePicker

                                // SECTION: IDENTITY
                                sectionCard(title: "MEMBER IDENTITY", icon: "person.text.rectangle") {
                                    VStack(spacing: 20) {
                                        CustomTextField(
                                            title: "Username",
                                            placeholder: "e.g. john_doe",
                                            iconName: "person.fill",
                                            text: $username,
                                            errorMessage: viewModel.usernameError
                                        )

                                        CustomTextField(
                                            title: "Display Name",
                                            placeholder: "e.g. John Doe",
                                            iconName: "textformat",
                                            text: $displayName,
                                            errorMessage: viewModel.displayNameError
                                        )
                                    }
                                }

                                // SECTION: CONTACT
                                sectionCard(title: "CONTACT INFORMATION", icon: "envelope.badge") {
                                    VStack(spacing: 20) {
                                        CustomTextField(
                                            title: "Email Address",
                                            placeholder: "john@example.com",
                                            iconName: "envelope.fill",
                                            text: $email,
                                            errorMessage: viewModel.emailError
                                        )

                                        CustomTextField(
                                            title: "Phone Number",
                                            placeholder: "+94 7X XXX XXXX",
                                            iconName: "phone.fill",
                                            text: $phone,
                                            errorMessage: viewModel.phoneError
                                        )
                                    }
                                }

                                // SECTION: SECURITY
                                sectionCard(title: "SECURITY ACCESS", icon: "lock.shield") {
                                    VStack(spacing: 20) {
                                        SecureCustomTextField(
                                            title: "Initial Password",
                                            placeholder: "Minimum 8 characters",
                                            iconName: "lock.fill",
                                            text: $password,
                                            errorMessage: viewModel.passwordError
                                        )

                                        SecureCustomTextField(
                                            title: "Confirm Password",
                                            placeholder: "Re-enter password",
                                            iconName: "lock.shield.fill",
                                            text: $confirmPassword,
                                            errorMessage: viewModel.confirmPasswordError
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        PrimaryButton(title: viewModel.isSaving ? "Provisioning..." : "Create Member Account") {
                            createMember()
                        }
                        .disabled(viewModel.isSaving)
                        .scaleEffect(viewModel.isSaving ? 0.98 : 1.0)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .navigationBarHidden(true)
        .onChange(of: selectedPhotoItem) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self) {
                    DispatchQueue.main.async {
                        memberPhotoData = data
                    }
                }
            }
        }
    }

    private var rolePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MEMBER ROLE")
                .scaledFont(size: 11, weight: .bold)
                .foregroundColor(.elevateTextGray)
                .tracking(1)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                ForEach(roles, id: \.self) { role in
                    roleCard(role: role)
                }
            }
        }
    }

    private func roleCard(role: String) -> some View {
        let isSelected = selectedRole == role
        return Button(action: {
            HapticManager.shared.playImpact(style: .light)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedRole = role
            }
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.elevateDarkGreen.opacity(0.1) : Color.elevateLightGray.opacity(0.3))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: role == "Manager" ? "person.badge.shield.checkmark.fill" : "wrench.and.screwdriver.fill")
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? .elevateDarkGreen : .gray)
                }

                Text(role.uppercased())
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundColor(isSelected ? .elevateDarkGreen : .gray)
                    .tracking(0.5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.white : Color.elevateLightGray.opacity(0.2))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.elevateDarkGreen : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? Color.elevateDarkGreen.opacity(0.15) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func sectionCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
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
            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
        }
    }

    private var profilePhotoCard: some View {
        VStack(spacing: 16) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color.elevateLightGray.opacity(0.5))
                        .frame(width: 110, height: 110)
                        .overlay(
                            Group {
                                if let data = memberPhotoData, let image = UIImage(data: data) {
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
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    Circle()
                        .fill(Color.elevateDarkGreen)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
            .buttonStyle(.plain)

            Text("Attach Profile Photo")
                .scaledFont(size: 14, weight: .bold)
                .foregroundColor(.elevateDarkGreen)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
    }

    private func createMember() {
        guard let user = appSession.currentUser else { return }
        
        // Use the new validation logic
        guard viewModel.validate(
            username: username,
            displayName: displayName,
            email: email,
            phone: phone,
            password: password,
            confirmPassword: confirmPassword
        ) else {
            HapticManager.shared.playNotification(type: .error)
            return
        }

        let roleKey = selectedRole.uppercased() == "MANAGER" ? "MANAGER" : "TECHNICIAN"
        viewModel.createMember(
            organizationId: user.organizationId,
            username: username,
            displayName: displayName,
            role: roleKey,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone,
            password: password.isEmpty ? nil : password
        ) { created in
            if let created {
                HapticManager.shared.playNotification(type: .success)
                if let data = memberPhotoData {
                    ProfilePhotoService.shared.uploadProfilePhoto(data: data, userId: created.id) { result in
                        if case .success(let url) = result {
                            ProfileImageStore.shared.saveRemoteUrl(url, for: created.id)
                        }
                        _ = ProfileImageStore.shared.saveImage(data, for: created.id)
                    }
                }
                router.currentScreen = .members
                router.selectedTab = .profile
            }
        }
    }
}

#Preview {
    ManagerAddMemberView()
        .environmentObject(AppSession())
}
