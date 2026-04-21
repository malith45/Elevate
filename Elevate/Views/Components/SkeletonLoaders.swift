import SwiftUI

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: phase),
                            .init(color: .white.opacity(0.3), location: phase + 0.1),
                            .init(color: .clear, location: phase + 0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: -geo.size.width + (geo.size.width * 2 * phase))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1.0
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

struct SkeletonCard: View {
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Circle()
                    .fill(settings.secondaryText.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(settings.secondaryText.opacity(0.2))
                        .frame(width: 120, height: 16)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(settings.secondaryText.opacity(0.1))
                        .frame(width: 80, height: 12)
                }
            }
            
            RoundedRectangle(cornerRadius: 8)
                .fill(settings.secondaryText.opacity(0.1))
                .frame(height: 100)
            
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(settings.secondaryText.opacity(0.1))
                    .frame(width: 60, height: 16)
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(settings.secondaryText.opacity(0.2))
                    .frame(width: 100, height: 24)
            }
        }
        .padding(20)
        .background(settings.surfaceColor)
        .cornerRadius(16)
        .shimmer()
    }
}

struct SkeletonDetailHeader: View {
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(settings.secondaryText.opacity(0.2))
                    .frame(width: 200, height: 32)
                RoundedRectangle(cornerRadius: 4)
                    .fill(settings.secondaryText.opacity(0.1))
                    .frame(width: 140, height: 18)
            }
            
            RoundedRectangle(cornerRadius: 16)
                .fill(settings.secondaryText.opacity(0.1))
                .frame(height: 180)
            
            VStack(spacing: 12) {
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(settings.secondaryText.opacity(0.1))
                        .frame(height: 60)
                }
            }
        }
        .shimmer()
    }
}

struct SkeletonTaskRow: View {
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(settings.secondaryText.opacity(0.1))
                .frame(width: 6)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(settings.secondaryText.opacity(0.15))
                        .frame(width: 50, height: 16)
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(settings.secondaryText.opacity(0.1))
                        .frame(width: 60, height: 12)
                }
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(settings.secondaryText.opacity(0.2))
                    .frame(width: 140, height: 18)
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(settings.secondaryText.opacity(0.1))
                        .frame(width: 28, height: 28)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(settings.secondaryText.opacity(0.1))
                        .frame(width: 100, height: 14)
                }
            }
            .padding(16)
        }
        .background(settings.surfaceColor)
        .cornerRadius(16)
        .shimmer()
    }
}

#Preview {
    ZStack {
        Color.elevateLightGray.ignoresSafeArea()
        ScrollView {
            VStack(spacing: 24) {
                SkeletonCard()
                SkeletonDetailHeader()
            }
            .padding(24)
        }
    }
}
