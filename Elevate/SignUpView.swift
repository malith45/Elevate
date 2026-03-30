import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var username = ""
    @State private var companyCode = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
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
                // Back button manually placed if needed, or rely on dismiss internally
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(primaryText)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Logo
                Image("AppName")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 160, maxHeight: 60)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                
                // Form Card
                VStack(spacing: 16) {
                    Text("Sign Up")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(primaryText)
                        .padding(.bottom, 5)
                    
                    // Username Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Username")
                            .font(.footnote)
                            .foregroundColor(primaryText)
                        
                        TextField("", text: $username)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .background(textBoxColor)
                            .cornerRadius(10)
                            .foregroundColor(primaryText)
                    }
                    
                    // Company Code Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Company Code")
                            .font(.footnote)
                            .foregroundColor(primaryText)
                        
                        TextField("", text: $companyCode)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .background(textBoxColor)
                            .cornerRadius(10)
                            .foregroundColor(primaryText)
                    }
                    
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
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
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
                    
                    // Confirm Password Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Confirm Password")
                            .font(.footnote)
                            .foregroundColor(primaryText)
                        
                        HStack {
                            if showConfirmPassword {
                                TextField("", text: $confirmPassword)
                                    .foregroundColor(primaryText)
                            } else {
                                SecureField("", text: $confirmPassword)
                                    .foregroundColor(primaryText)
                            }
                            
                            Button(action: { showConfirmPassword.toggle() }) {
                                Image(systemName: showConfirmPassword ? "eye.fill" : "eye")
                                    .foregroundColor(secTextColor)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(textBoxColor)
                        .cornerRadius(10)
                    }
                    
                    // Sign Up Button
                    Button(action: {
                        // Action for Sign Up
                    }) {
                        Text("Sign Up")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(buttonColor)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                    
                    // Already have an account shortcut
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.footnote)
                            .foregroundColor(secTextColor)
                        Button("Sign In") {
                            dismiss()
                        }
                        .font(.footnote)
                        .foregroundColor(linkColor)
                    }
                    .padding(.top, 6)
                }
                .padding(28)
                .background(secBgColor)
                .cornerRadius(24)
                .padding(.horizontal, 20)
                
                Spacer(minLength: 0)
                
                // Footer
                HStack(spacing: 4) {
                    Text("By signing up, you agree to our")
                        .font(.footnote)
                        .foregroundColor(secTextColor)
                    Button("Terms of Service") {
                        // Terms action
                    }
                    .font(.footnote)
                    .foregroundColor(linkColor)
                }
                .padding(.top, 5)
                .padding(.bottom, 10)
            }
        }
    }
}

#Preview {
    SignUpView()
}
