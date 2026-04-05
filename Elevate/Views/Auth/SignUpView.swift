import SwiftUI

struct SignUpView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var orgName = ""
    @State private var orgId = ""
    @State private var ownerUsername = ""
    @State private var password = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 40)
                
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.elevateLightGray)
                            .frame(width: 64, height: 64)
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.elevateDarkGreen)
                    }
                    
                    Text("Create Organization")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                }
                .padding(.bottom, 8)
                
                // Form Fields
                VStack(spacing: 16) {
                    CustomTextField(
                        title: "ORGANIZATION NAME",
                        placeholder: "e.g. Acme Corp",
                        iconName: "building.2",
                        text: $orgName
                    )
                    
                    CustomTextField(
                        title: "ORGANIZATION ID",
                        placeholder: "acme-global-01",
                        iconName: "building.2",
                        text: $orgId
                    )
                    
                    CustomTextField(
                        title: "OWNER USERNAME",
                        placeholder: "admin_user",
                        iconName: "person",
                        text: $ownerUsername
                    )
                    
                    SecureCustomTextField(
                        title: "SECURE PASSWORD",
                        placeholder: "••••••••",
                        iconName: "lock",
                        text: $password
                    )
                }
                
                // Action Buttons
                VStack(spacing: 16) {
                    PrimaryButton(title: "Create Account", iconName: "arrow.right") {
                        // Create Account Action
                    }
                }
                .padding(.top, 16)
                
                Spacer().frame(height: 24)
                
                // Footer
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .font(.system(size: 14))
                        .foregroundColor(.elevateTextGray)
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Sign In")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.elevateDarkGreen)
                    }
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    SignUpView()
}
