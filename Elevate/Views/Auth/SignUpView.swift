import SwiftUI

struct SignUpView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = SignUpViewModel()
    
    @State private var orgName = ""
    @State private var orgId = ""
    @State private var ownerUsername = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var navigateToManager = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)
                
                // Header
                VStack(spacing: 16) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                    
                    Text("Create Organization")
                        .scaledFont(size: 24, weight: .bold, design: .rounded)
                }
                .padding(.bottom, 8)
                
                // Form Fields
                VStack(spacing: 16) {
                    CustomTextField(
                        title: "ORGANIZATION NAME",
                        placeholder: "Prime Elevators",
                        iconName: "building.2",
                        text: $orgName
                    )
                    
                    CustomTextField(
                        title: "ORGANIZATION ID",
                        placeholder: "ORG-000-00",
                        iconName: "building.2",
                        text: $orgId
                    )
                    
                    CustomTextField(
                        title: "USERNAME",
                        placeholder: "Your username",
                        iconName: "person",
                        text: $ownerUsername
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
                
                // Action Buttons
                VStack(spacing: 16) {
                    PrimaryButton(title: "Create Account", iconName: "arrow.right") {
                        validateAndSubmit()
                    }
                }
                .padding(.top, 16)
                
                Spacer().frame(height: 24)
                
                // Footer
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .scaledFont(size: 14)
                        .foregroundColor(.elevateTextGray)
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Sign In")
                            .scaledFont(size: 14, weight: .bold)
                            .foregroundColor(.elevateDarkGreen)
                    }
                }
                .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
        .navigationBarHidden(true)
        .alert("Sign Up", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .navigationDestination(isPresented: $navigateToManager) {
            ManagerMainTabView()
                .environmentObject(appSession)
        }
    }

    private func validateAndSubmit() {
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedPassword == trimmedConfirm else {
            viewModel.errorMessage = "Passwords do not match."
            return
        }

        viewModel.signUp(
            organizationName: orgName,
            organizationId: orgId,
            username: ownerUsername,
            password: trimmedPassword
        ) { user in
            if let user = user {
                appSession.signIn(user: user)
                navigateToManager = true
            }
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(AppSession())
}
