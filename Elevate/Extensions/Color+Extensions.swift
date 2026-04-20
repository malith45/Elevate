import SwiftUI
import Combine

extension Color {
    static var elevateDarkGreen: Color {
        AccessibilitySettings.shared.isHighContrast ? Color(red: 50/255, green: 215/255, blue: 75/255) : Color(red: 1/255, green: 74/255, blue: 63/255)
    }
    static var elevateLightGray: Color {
        AccessibilitySettings.shared.isHighContrast ? Color(red: 28/255, green: 28/255, blue: 30/255) : Color(red: 247/255, green: 248/255, blue: 248/255)
    }
    static var elevateTextGray: Color {
        AccessibilitySettings.shared.isHighContrast ? Color(red: 235/255, green: 235/255, blue: 245/255).opacity(0.6) : Color(red: 135/255, green: 145/255, blue: 152/255)
    }
    static var elevateAccentWhite: Color {
        AccessibilitySettings.shared.isHighContrast ? Color.white : Color.white.opacity(0.9)
    }
    
    // MARK: - Semantic Tokens
    static var appBackground: Color { AccessibilitySettings.shared.appBackground }
    static var surfaceColor: Color { AccessibilitySettings.shared.surfaceColor }
    static var primaryText: Color { AccessibilitySettings.shared.primaryText }
    static var secondaryText: Color { AccessibilitySettings.shared.secondaryText }
    static var accentColor: Color { AccessibilitySettings.shared.accentColor }
    static var cardStroke: Color { AccessibilitySettings.shared.cardStroke }
}
