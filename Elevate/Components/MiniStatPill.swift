import SwiftUI

struct MiniStatPill: View {
    let title: String
    let value: String
    let color: Color
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .scaledFont(size: 9, weight: .black)
                .foregroundColor(settings.secondaryText)
            Text(value)
                .scaledFont(size: 18, weight: .bold, design: .rounded)
                .foregroundColor(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(settings.surfaceColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
    }
}
