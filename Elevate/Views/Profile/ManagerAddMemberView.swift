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
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Add New Member")
                                .scaledFont(size: 22, weight: .bold, design: .rounded)
                            Text("Create a team account")
                                .scaledFont(size: 12)
                                .foregroundColor(.elevateTextGray)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)

                        VStack(spacing: 16) {
                            profilePhotoCard

                            rolePicker

                            CustomTextField(
                                title: "USERNAME",
                                placeholder: "e.g. john_doe",
                                iconName: "person",
                                text: $username
                            )

                            CustomTextField(
                                title: "DISPLAY NAME",
                                placeholder: "e.g. John Doe",
                                iconName: "textformat",
                                text: $displayName
                            )

                            CustomTextField(
                                title: "EMAIL ADDRESS",
                                placeholder: "john@example.com",
                                iconName: "envelope",
                                text: $email
                            )

                            CustomTextField(
                                title: "PHONE NUMBER",
                                placeholder: "+94 7X XXX XXXX",
                                iconName: "phone",
                                text: $phone
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

                        PrimaryButton(title: "Create Member") {
                            createMember()
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
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
        .alert("Add Member", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var rolePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ROLE")
                .scaledFont(size: 12, weight: .bold)
                .foregroundColor(.elevateTextGray)

            Menu {
                Picker("Role", selection: $selectedRole) {
                    ForEach(roles, id: \.self) { role in
                        Text(role).tag(role)
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.2")
                        .foregroundColor(.elevateTextGray)
                    Text(selectedRole)
                        .scaledFont(size: 16, weight: .semibold)
                        .foregroundColor(.black)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.elevateTextGray)
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
            }
        }
    }

    private var profilePhotoCard: some View {
        VStack(spacing: 20) {
            Circle()
                .fill(Color.elevateDarkGreen)
                .frame(width: 100, height: 100)
                .overlay(
                    Group {
                        if let data = memberPhotoData, let image = UIImage(data: data) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                    }
                )
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

            VStack(spacing: 8) {
                Text("PROFILE PHOTO")
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundColor(.elevateTextGray)
                
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Text("Choose Photo")
                        .scaledFont(size: 14, weight: .bold)
                        .foregroundColor(.elevateDarkGreen)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.elevateDarkGreen.opacity(0.1))
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }

    private func createMember() {
        guard let user = appSession.currentUser else { return }
        guard password == confirmPassword else {
            viewModel.errorMessage = "Passwords do not match."
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
