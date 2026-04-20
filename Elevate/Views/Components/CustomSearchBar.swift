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
        .padding(12)
        .background(settings.surfaceColor)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(settings.cardStroke, lineWidth: settings.isHighContrast ? 2 : 0)
        )
    }
}
