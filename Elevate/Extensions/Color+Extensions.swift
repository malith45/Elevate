import SwiftUI
import Combine

extension Color {
    static let elevateDarkGreen = Color(red: 1/255, green: 74/255, blue: 63/255)
    static let elevateLightGray = Color(red: 247/255, green: 248/255, blue: 248/255)
    static let elevateTextGray = Color(red: 135/255, green: 145/255, blue: 152/255)
    static let elevateAccentWhite = Color.white.opacity(0.9)
    
    // MARK: - Semantic Tokens
    static var appBackground: Color { AccessibilitySettings.shared.appBackground }
    static var surfaceColor: Color { AccessibilitySettings.shared.surfaceColor }
    static var primaryText: Color { AccessibilitySettings.shared.primaryText }
    static var secondaryText: Color { AccessibilitySettings.shared.secondaryText }
    static var accentColor: Color { AccessibilitySettings.shared.accentColor }
    static var cardStroke: Color { AccessibilitySettings.shared.cardStroke }
}
