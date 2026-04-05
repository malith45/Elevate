import SwiftUI

struct SignInView: View {
    @State private var orgId = ""
    @State private var userId = ""
    @State private var password = ""
    @Binding var isAuthenticated: Bool
    @State private var showFaceID = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.elevateDarkGreen)
                    Text("Welcome !")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }
                .padding(.bottom, 16)
                
                // Form Fields
                VStack(spacing: 16) {
                    CustomTextField(
                        title: "ORGANIZATION ID",
                        placeholder: "ORG-000-00",
                        iconName: "building.2",
                        text: $orgId
                    )
                    
                    CustomTextField(
                        title: "USER IDENTIFICATION",
                        placeholder: "Username or ID",
                        iconName: "person",
                        text: $userId
                    )
                    
                    SecureCustomTextField(
                        title: "SECURITY KEY",
                        placeholder: "••••••••",
                        iconName: "lock",
                        text: $password,
                        titleAction: AnyView(
                            NavigationLink(destination: ForgotPasswordView()) {
                                Text("FORGOT PASSWORD?")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.elevateDarkGreen)
                            }
                        )
                    )
                }
                
                // Action Buttons
                VStack(spacing: 16) {
                    PrimaryButton(title: "Sign In", iconName: "arrow.right") {
                        isAuthenticated = true
                    }
                    
                    SecondaryButton(title: "Sign in with Face ID", iconName: "faceid") {
                        showFaceID = true
                    }
                    .fullScreenCover(isPresented: $showFaceID) {
                        FaceIDVerificationView(isAuthenticated: $isAuthenticated)
                    }
                }
                .padding(.top, 8)
                
                Spacer()
                
                // Footer
                VStack(spacing: 4) {
                    Text("Don't have an organization?")
                        .font(.system(size: 14))
                        .foregroundColor(.elevateTextGray)
                    
                    NavigationLink(destination: SignUpView()) {
                        Text("Create New Organization")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.elevateDarkGreen)
                    }
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    SignInView(isAuthenticated: .constant(false))
}
