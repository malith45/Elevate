import SwiftUI
import PhotosUI
import UIKit

struct ManagerAddMemberView: View {
    @Environment(\.managerTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = ManagerAddMemberViewModel()
    @ObservedObject var settings = AccessibilitySettings.shared
    @Environment(\.dismiss) private var dismiss
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
            settings.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                BackHeaderNav(isManager: true, onBack: {
                    dismiss()
                })
                .background(settings.surfaceColor)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Team Member")
                                .scaledFont(size: 28, weight: .bold, design: .rounded)
                                .foregroundColor(settings.primaryText)
                            Text("Provision a new technician or manager account with role-specific credentials.")
                                .scaledFont(size: 15)
                                .foregroundColor(settings.secondaryText)
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
                                            placeholder: "Strong password",
                                            iconName: "lock.fill",
                                            text: $password,
                                            errorMessage: viewModel.passwordError
                                        )

                                        PasswordRequirementsView(password: password)

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
                        .padding(.bottom, 120)
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
        }
        .buttonStyle(.plain)
    }

    private var profilePhotoCard: some View {
        VStack(spacing: 16) {
            ZStack {
                if let data = memberPhotoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 2))
                } else {
                    Circle()
                        .fill(settings.isHighContrast ? Color.black : settings.accentColor)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle().stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 2)
                        )
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        )
                }

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Circle()
                        .fill(settings.isHighContrast ? Color.black : Color.white)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle().stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 1)
                        )
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(settings.isHighContrast ? .white : settings.accentColor)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 4)
                }
                .offset(x: 35, y: 35)
            }

            VStack(spacing: 4) {
                Text("Account Photo")
                    .scaledFont(size: 16, weight: .bold)
                    .foregroundColor(settings.primaryText)
                Text("Recommended: Square JPG or PNG")
                    .scaledFont(size: 12)
                    .foregroundColor(settings.secondaryText)
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(settings.surfaceColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
    }

    private func sectionCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(settings.isHighContrast ? Color.black : settings.accentColor.opacity(0.1))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle().stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 1)
                        )
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(settings.accentColor)
                }

                Text(title)
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundColor(settings.secondaryText)
                    .tracking(1)
            }

            content()
        }
        .padding(24)
        .background(settings.surfaceColor)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
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
                dismiss()
            }
        }
    }
}

#Preview {
    ManagerAddMemberView()
        .environmentObject(AppSession())
}
