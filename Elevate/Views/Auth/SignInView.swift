import SwiftUI
import LocalAuthentication

struct SignInView: View {
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = SignInViewModel()
    @State private var showAuthError = false
    @State private var authErrorMessage = ""
    @AppStorage("biometricLoginEnabled") private var biometricLoginEnabled = true
    @ObservedObject var settings = AccessibilitySettings.shared
    private let sessionStore = SessionStore.shared
    private let localStorage = LocalStorageService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()
                    
                    // Header
                    VStack(spacing: 12) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                        
                        Text("Welcome Back")
                            .scaledFont(size: 32, weight: .black, design: .rounded)
                            .foregroundColor(settings.primaryText)
                        
                        Text("Sign in to manage your workspace")
                            .scaledFont(size: 15)
                            .foregroundColor(settings.secondaryText)
                    }
                    .padding(.bottom, 8)
                    
                    // Glassmorphism Form
                    VStack(spacing: 20) {
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
                                    Text("FORGOT?")
                                        .scaledFont(size: 11, weight: .bold)
                                        .foregroundColor(settings.accentColor)
                                }
                            )
                        )
                    }
                    .padding(24)
                    .background(
                        settings.surfaceColor.opacity(settings.isHighContrast ? 1.0 : 0.8)
                    )
                    .background(.ultraThinMaterial)
                    .cornerRadius(32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        PrimaryButton(title: "Sign In", iconName: "arrow.right") {
                            HapticManager.shared.playImpact(style: .medium)
                            viewModel.signIn(appSession: appSession)
                        }

                        if biometricLoginEnabled {
                            SecondaryButton(title: "Sign in with Face ID", iconName: "faceid") {
                                authenticateWithBiometrics()
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Footer
                    HStack(spacing: 4) {
                        Text("New here?")
                            .scaledFont(size: 14)
                            .foregroundColor(settings.secondaryText)
                        
                        NavigationLink(destination: SignUpView()) {
                            Text("Create Organization")
                                .scaledFont(size: 14, weight: .bold)
                                .foregroundColor(settings.accentColor)
                        }
                    }
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 24)
            }
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
