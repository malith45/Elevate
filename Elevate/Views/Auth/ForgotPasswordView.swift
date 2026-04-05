import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var identification = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)
            
            // Header
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.elevateLightGray)
                        .frame(width: 64, height: 64)
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.elevateDarkGreen)
                }
                
                Text("Forgot Password")
                    .scaledFont(size: 24, weight: .bold, design: .rounded)
                
                Text("Enter your email or user ID to receive a\nrecovery link")
                    .scaledFont(size: 14)
                    .foregroundColor(.elevateTextGray)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 24)
            
            // Form Fields
            VStack(spacing: 16) {
                CustomTextField(
                    title: "IDENTIFICATION",
                    placeholder: "Email or User ID",
                    iconName: "person",
                    text: $identification
                )
            }
            
            // Action Buttons
            VStack(spacing: 24) {
                PrimaryButton(title: "Send Recovery Link", iconName: nil) {
                    // Send Recovery Action
                }
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.left")
                        Text("Back to Sign In")
                            .fontWeight(.bold)
                    }
                    .scaledFont(size: 14)
                    .foregroundColor(.elevateDarkGreen)
                }
            }
            .padding(.top, 16)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .navigationBarHidden(true)
    }
}

#Preview {
    ForgotPasswordView()
}
