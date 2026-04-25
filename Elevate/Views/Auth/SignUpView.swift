import SwiftUI

struct SignUpView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = SignUpViewModel()
    @ObservedObject var settings = AccessibilitySettings.shared
    
    @State private var orgName = ""
    @State private var orgId = ""
    @State private var ownerUsername = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var navigateToManager = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        Spacer().frame(height: 20)
                        
                        // Header
                        VStack(spacing: 12) {
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                            
                            Text("New Organization")
                                .scaledFont(size: 28, weight: .black, design: .rounded)
                                .foregroundColor(settings.primaryText)
                            
                            Text("Start managing your team effectively")
                                .scaledFont(size: 14)
                                .foregroundColor(settings.secondaryText)
                        }
                        
                        // Form
                        VStack(spacing: 20) {
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
                            
                            PasswordRequirementsView(password: password)

                            SecureCustomTextField(
                                title: "CONFIRM PASSWORD",
                                placeholder: "••••••••",
                                iconName: "lock",
                                text: $confirmPassword
                            )
                        }
                        .padding(24)
                        .background(settings.surfaceColor)
                        .cornerRadius(32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                        )
                        .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 5)
                        
                        // Action Buttons
                        PrimaryButton(title: "Create Account", iconName: "checkmark.circle.fill") {
                            HapticManager.shared.playImpact(style: .medium)
                            validateAndSubmit()
                        }
                        
                        // Footer
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .scaledFont(size: 14)
                                .foregroundColor(settings.secondaryText)
                            
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Sign In")
                                    .scaledFont(size: 14, weight: .bold)
                                    .foregroundColor(settings.accentColor)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
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
