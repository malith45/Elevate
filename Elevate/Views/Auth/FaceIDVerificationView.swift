import SwiftUI

struct FaceIDVerificationView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var isAuthenticated: Bool
    
    var body: some View {
        ZStack {
            // Background radial gradient mimicking the screenshot's blur
            RadialGradient(
                gradient: Gradient(colors: [Color.white, Color.elevateLightGray]),
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.elevateDarkGreen)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                VStack(spacing: 24) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white)
                            .frame(width: 96, height: 96)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                            
                        Circle()
                            .fill(Color.elevateDarkGreen)
                            .frame(width: 48, height: 48)
                            
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Face ID Verified")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.elevateDarkGreen)
                        
                        Text("AUTHENTICATION SUCCESSFUL")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.elevateTextGray)
                    }
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                presentationMode.wrappedValue.dismiss()
                isAuthenticated = true
            }
        }
    }
}

#Preview {
    FaceIDVerificationView(isAuthenticated: .constant(false))
}
