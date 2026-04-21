import SwiftUI

struct CustomSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    @ObservedObject var settings = AccessibilitySettings.shared

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(settings.secondaryText)
            TextField(placeholder, text: $text)
                .scaledFont(size: 14)
                .foregroundColor(settings.primaryText)
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(settings.secondaryText)
                }
            }
        }
        .padding(14)
        .background(settings.surfaceColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(settings.cardStroke, lineWidth: settings.isHighContrast ? 2 : 1)
        )
    }
}
