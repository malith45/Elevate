import SwiftUI

struct ManagerEditProfileView: View {
    @Environment(\.managerTabRouter) private var router
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""

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
                            // TODO: Persist profile edits.
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .navigationBarHidden(true)
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
}

#Preview {
    ManagerEditProfileView()
}
