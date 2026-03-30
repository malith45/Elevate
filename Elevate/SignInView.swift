import SwiftUI
import LocalAuthentication

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    @State private var showPassword = false
    @State private var showSignUp = false
    @State private var showDashboard = false
    
    // Extracted Colors
    let bgColor = Color(red: 15/255, green: 23/255, blue: 42/255) // #0F172A
    let primaryText = Color(red: 248/255, green: 250/255, blue: 252/255) // #F8FAFC
    let secBgColor = Color(red: 30/255, green: 41/255, blue: 59/255) // #1E293B
    let textBoxColor = Color(red: 51/255, green: 65/255, blue: 85/255) // #334155
    let secTextColor = Color(red: 203/255, green: 213/255, blue: 245/255) // #CBD5F5
    let buttonColor = Color(red: 37/255, green: 99/255, blue: 235/255) // #2563EB
    let linkColor = Color(red: 14/255, green: 165/255, blue: 233/255) // #0EA5E9

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            VStack {
                // Image Logo from Assets
                Image("AppName")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 160, maxHeight: 60)
                    .padding(.top, 60)
                    .padding(.bottom, 30)
                
                // Form Card (More compact and beautiful)
                VStack(spacing: 20) {
                    Text("Sign In")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(primaryText)
                        .padding(.bottom, 5)
                    
                    // Email Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email Address")
                            .font(.footnote)
                            .foregroundColor(primaryText)
                        
                        TextField("", text: $email)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .background(textBoxColor)
                            .cornerRadius(10)
                            .foregroundColor(primaryText)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.footnote)
                            .foregroundColor(primaryText)
                        
                        HStack {
                            if showPassword {
                                TextField("", text: $password)
                                    .foregroundColor(primaryText)
                            } else {
                                SecureField("", text: $password)
                                    .foregroundColor(primaryText)
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.fill" : "eye")
                                    .foregroundColor(secTextColor)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(textBoxColor)
                        .cornerRadius(10)
                    }
                    
                    // Remember Me & Forgot Password
                    HStack {
                        Button(action: { rememberMe.toggle() }) {
                            HStack(spacing: 8) {
                                Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                    .foregroundColor(rememberMe ? linkColor : secTextColor)
                                    .font(.system(size: 14))
                                Text("Remember me")
                                    .font(.footnote)
                                    .foregroundColor(primaryText)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Forgot password?") {
                            // Forgot password action
                        }
                        .font(.footnote)
                        .foregroundColor(linkColor)
                    }
                    .padding(.top, -4)
                    
                    // Sign In Button
                    Button(action: {
                        // Transition to dashboard
                        showDashboard = true
                    }) {
                        Text("Sign In")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(buttonColor)
                            .cornerRadius(10)
                    }
                    .padding(.top, 6)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(textBoxColor)
                            .frame(height: 1)
                        Text("Or continue with")
                            .font(.footnote)
                            .foregroundColor(secTextColor)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 12)
                        Rectangle()
                            .fill(textBoxColor)
                            .frame(height: 1)
                    }
                    .padding(.vertical, 4)
                    
                    // Face ID / Touch ID Button
                    Button(action: {
                        authenticate()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "faceid")
                                .font(.body)
                            Text("Face ID / Touch ID")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(textBoxColor)
                        .cornerRadius(10)
                    }
                    
                    // Sign Up Link Shortcut
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.footnote)
                            .foregroundColor(secTextColor)
                        Button("Sign Up") {
                            showSignUp = true
                        }
                        .font(.footnote)
                        .foregroundColor(linkColor)
                    }
                    .padding(.top, 4)
                }
                .padding(28)
                .background(secBgColor)
                .cornerRadius(24)
                .padding(.horizontal, 20)
                
                // Footer
                HStack(spacing: 4) {
                    Text("By signing in, you agree to our")
                        .font(.footnote)
                        .foregroundColor(secTextColor)
                    Button("Terms of Service") {
                        // Terms action
                    }
                    .font(.footnote)
                    .foregroundColor(linkColor)
                }
                .padding(.top, 30)
                .padding(.bottom, 20)
            }
        }
        .fullScreenCover(isPresented: $showSignUp) {
            SignUpView()
        }
        .fullScreenCover(isPresented: $showDashboard) {
            HomeDashboardView()
        }
    }
    
    // Biometric Authentication Controller
    func authenticate() {
        let context = LAContext()
        var error: NSError?

        // Check if biometrics (Face ID / Touch ID) are mathematically available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Log in to your Elevate account"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                // UI updates must happen on the main thread
                DispatchQueue.main.async {
                    if success {
                        // Authorized securely
                        showDashboard = true
                    } else {
                        print("Authentication failed: \(authenticationError?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        } else {
            // Hardware doesn't support it or isn't enrolled
            print("Biometrics unavailable: \(error?.localizedDescription ?? "No biometrics")")
        }
    }
}

#Preview {
    SignInView()
}
