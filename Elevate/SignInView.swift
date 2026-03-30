import SwiftUI

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    @State private var showPassword = false
    
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
                // Logo Section - Built with SwiftUI to ensure perfect crispness and sizing
                HStack(alignment: .center, spacing: 2) {
                    Text("elevate")
                         .font(.system(size: 42, weight: .semibold, design: .rounded))
                         .foregroundColor(.white)
                    
                    ZStack {
                        Image(systemName: "chevron.up.forward")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(Color(red: 35/255, green: 200/255, blue: 162/255))
                            .offset(x: -6, y: 6)
                        
                        Image(systemName: "chevron.up.forward")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(Color(red: 35/255, green: 200/255, blue: 162/255))
                    }
                    .offset(x: 2, y: -12)
                }
                .padding(.top, 50)
                .padding(.bottom, 30)
                
                // Form Card
                VStack(spacing: 24) {
                    Text("Sign In")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(primaryText)
                        .padding(.vertical, 5)
                    
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Address")
                            .font(.subheadline)
                            .foregroundColor(primaryText)
                        
                        TextField("", text: $email)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(textBoxColor)
                            .cornerRadius(10)
                            .foregroundColor(primaryText)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
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
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(textBoxColor)
                        .cornerRadius(10)
                    }
                    
                    // Remember Me & Forgot Password
                    HStack {
                        Button(action: { rememberMe.toggle() }) {
                            HStack(spacing: 8) {
                                Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                    .foregroundColor(rememberMe ? linkColor : secTextColor)
                                Text("Remember me")
                                    .font(.subheadline)
                                    .foregroundColor(primaryText)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Forgot password?") {
                            // Forgot password action
                        }
                        .font(.subheadline)
                        .foregroundColor(linkColor)
                    }
                    
                    // Sign In Button
                    Button(action: {
                        // Action for Sign In
                    }) {
                        Text("Sign In")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(buttonColor)
                            .cornerRadius(10)
                    }
                    .padding(.top, 4)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(textBoxColor)
                            .frame(height: 1)
                        Text("Or continue with")
                            .font(.subheadline)
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
                        // Biometrics action
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "faceid")
                                .font(.title3)
                            Text("Face ID / Touch ID")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(textBoxColor)
                        .cornerRadius(10)
                    }
                    
                    // Support Link
                    VStack(spacing: 6) {
                        Text("Need help accessing your account?")
                            .font(.footnote)
                            .foregroundColor(secTextColor)
                        Button("Contact Support") {
                            // Support action
                        }
                        .font(.footnote)
                        .foregroundColor(linkColor)
                    }
                    .padding(.top, 6)
                }
                .padding(32)
                .background(secBgColor)
                .cornerRadius(24)
                .padding(.horizontal, 20)
                
                Spacer()
                
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
                .padding(.bottom, 30)
            }
        }
    }
}

#Preview {
    SignInView()
}
