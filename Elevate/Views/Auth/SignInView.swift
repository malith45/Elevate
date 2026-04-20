import SwiftUI
import LocalAuthentication

struct SignInView: View {
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = SignInViewModel()
    @State private var showAuthError = false
    @State private var authErrorMessage = ""
    @AppStorage("biometricLoginEnabled") private var biometricLoginEnabled = true
    private let sessionStore = SessionStore.shared
    private let localStorage = LocalStorageService.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Header
                VStack(spacing: 8) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                    Text("Welcome !")
                        .scaledFont(size: 28, weight: .bold, design: .rounded)
                }
                .padding(.bottom, 16)
                
                // Form Fields
                VStack(spacing: 16) {
                    CustomTextField(
                        title: "ORGANIZATION ID",
                        placeholder: "ORG-000-00",
                        iconName: "building.2",
                        text: $viewModel.organizationId
                    )
                    
                    CustomTextField(
                        title: "USERNAME",
                        placeholder: "Your username",
                        iconName: "person",
                        text: $viewModel.username
                    )
                    
                    SecureCustomTextField(
                        title: "PASSWORD",
                        placeholder: "••••••••",
                        iconName: "lock",
                        text: $viewModel.password,
                        titleAction: AnyView(
                            NavigationLink(destination: ForgotPasswordView()) {
                                Text("FORGOT PASSWORD?")
                                    .scaledFont(size: 11, weight: .bold)
                                    .foregroundColor(.elevateDarkGreen)
                            }
                        )
                    )
                }
                
                // Action Buttons
                VStack(spacing: 16) {
                    PrimaryButton(title: "Sign In", iconName: "arrow.right") {
                        viewModel.signIn(appSession: appSession)
                    }

                    if biometricLoginEnabled {
                        SecondaryButton(title: "Sign in with Face ID", iconName: "faceid") {
                            authenticateWithBiometrics()
                        }
                    }
                }
                .padding(.top, 8)
                
                Spacer()
                
                // Footer
                VStack(spacing: 4) {
                    Text("Don't have an organization?")
                        .scaledFont(size: 14)
                        .foregroundColor(.elevateTextGray)
                    
                    NavigationLink(destination: SignUpView()) {
                        Text("Create New Organization")
                            .scaledFont(size: 14, weight: .bold)
                            .foregroundColor(.elevateDarkGreen)
                    }
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
            .navigationBarHidden(true)
            .alert("Authentication Failed", isPresented: $showAuthError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(authErrorMessage)
            }
            .alert("Sign In Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        context.localizedFallbackTitle = ""
        context.localizedCancelTitle = "Cancel"

        let policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics
        guard context.canEvaluatePolicy(policy, error: &error) else {
            showAuthError(message: error?.localizedDescription ?? "Biometric authentication is not available.")
            return
        }

        let reason = "Use Face ID or Touch ID to sign in."
        context.evaluatePolicy(policy, localizedReason: reason) { success, authError in
            DispatchQueue.main.async {
                if success {
                    if appSession.currentUser != nil {
                        return
                    }

                    guard let userId = sessionStore.getUserId(),
                          let user = localStorage.fetchUser(id: userId)
                    else {
                        showAuthError(message: "No saved session found. Please sign in with your password first.")
                        return
                    }

                    appSession.signIn(user: user)
                } else {
                    showAuthError(message: authError?.localizedDescription ?? "Authentication failed.")
                }
            }
        }
    }

    private func showAuthError(message: String) {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        authErrorMessage = trimmed.isEmpty ? "Authentication failed. Please try again." : trimmed
        showAuthError = true
    }
}

#Preview {
    SignInView()
        .environmentObject(AppSession())
}
