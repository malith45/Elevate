import SwiftUI

struct ManagerAddMemberView: View {
    @Environment(\.managerTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = ManagerAddMemberViewModel()
    @State private var selectedRole = "Technician"
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""

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
                                placeholder: "Member username",
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

                        PrimaryButton(title: "Create Member", iconName: "checkmark") {
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
        HStack(spacing: 16) {
            Circle()
                .fill(Color.elevateDarkGreen)
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text("PROFILE PHOTO")
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundColor(.elevateTextGray)
                Button(action: {
                    // TODO: Add photo picker.
                }) {
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
            role: roleKey,
            password: password
        ) { created in
            if created != nil {
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
