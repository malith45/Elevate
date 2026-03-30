import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    // UI Colors based on the provided design
    let backgroundColor = Color(red: 15/255.0, green: 23/255.0, blue: 42/255.0) // #0F172A
    let accentGreen = Color(red: 35/255.0, green: 200/255.0, blue: 162/255.0) // Vibrant green
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                Image("SplashIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250) // Raw image size
                    .scaleEffect(size)
                    .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.0)) {
                        self.size = 1.0
                        self.opacity = 1.0
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
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
