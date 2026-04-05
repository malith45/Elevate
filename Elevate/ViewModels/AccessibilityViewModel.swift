import Foundation
import Combine

final class AccessibilityViewModel: ObservableObject {
    @Published var isHighContrast = false
    @Published var isVoiceOver = false
    @Published var textSize: Double = 0.5
    @Published var hapticFeedback = true
}
