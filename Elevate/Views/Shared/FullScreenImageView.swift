import SwiftUI

struct FullScreenImageView: View {
    let urlString: String
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settings = AccessibilitySettings.shared
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Image Content
            VStack {
                Spacer()
                
                HighFidelityImageView(urlString: urlString, placeholderIcon: "photo", cornerRadius: 0)
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                scale *= delta
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                                withAnimation {
                                    if scale < 1.0 { scale = 1.0 }
                                    if scale > 3.0 { scale = 3.0 }
                                }
                            }
                    )
                
                Spacer()
            }
            
            // Top Bar
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(20)
                    
                    Spacer()
                }
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}
