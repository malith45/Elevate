import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0

    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                // Background radial gradient
                RadialGradient(
                    gradient: Gradient(colors: [Color.white, Color.elevateLightGray]),
                    center: .center,
                    startRadius: 50,
                    endRadius: 400
                )
                .ignoresSafeArea()
                
                Text("elevate")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.elevateDarkGreen)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .onAppear {
                        withAnimation(.easeOut(duration: 1.0)) {
                            self.scale = 1.0
                            self.opacity = 1.0
                        }
                    }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
