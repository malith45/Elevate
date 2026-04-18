import SwiftUI
import Combine
import AVFoundation

// MARK: - Voice Over Narrator
class VoiceOverManager: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = VoiceOverManager()
    private let synthesizer = AVSpeechSynthesizer()
    
    var isEnabled: Bool = UserDefaults.standard.bool(forKey: "isVoiceOverApp") {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "isVoiceOverApp")
            if isEnabled {
                speak("Voice Over audio narration enabled.")
            } else {
                synthesizer.stopSpeaking(at: .immediate)
            }
        }
    }
    
    private override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(_ text: String) {
        guard isEnabled else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }
}

// MARK: - Haptic Manager
class HapticManager {
    static let shared = HapticManager()
    
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    
    func playImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard hapticFeedback else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func playNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticFeedback else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    func playSelection() {
        guard hapticFeedback else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

// MARK: - Text Size Provider
class AccessibilitySettings: ObservableObject {
    static let shared = AccessibilitySettings()
    
    @Published var isHighContrast: Bool {
        didSet {
            UserDefaults.standard.set(isHighContrast, forKey: "isHighContrast")
        }
    }
    
    @Published var isVoiceOver: Bool {
        didSet {
            VoiceOverManager.shared.isEnabled = isVoiceOver
        }
    }

    @Published var textSize: Double {
        didSet {
            UserDefaults.standard.set(textSize, forKey: "textSize")
        }
    }
    @Published var hapticFeedback: Bool {
        didSet {
            UserDefaults.standard.set(hapticFeedback, forKey: "hapticFeedback")
        }
    }
    
    init() {
        self.isHighContrast = UserDefaults.standard.bool(forKey: "isHighContrast")
        self.isVoiceOver = VoiceOverManager.shared.isEnabled
        self.textSize = UserDefaults.standard.double(forKey: "textSize") > 0 ? UserDefaults.standard.double(forKey: "textSize") : 0.5
        self.hapticFeedback = UserDefaults.standard.object(forKey: "hapticFeedback") == nil ? true : UserDefaults.standard.bool(forKey: "hapticFeedback")
    }
    
    func getScaledFontSize(_ baseSize: CGFloat) -> CGFloat {
        // Map 0...1 to 0.8x to 1.5x scaling
        let scaleFactor = 0.8 + (textSize * 0.7)
        return baseSize * scaleFactor
    }
    
    func getDynamicTypeSize() -> DynamicTypeSize {
        // Map 0...1 to DynamicTypeSize levels
        switch textSize {
        case 0..<0.15: return .xSmall
        case 0.15..<0.3: return .small
        case 0.3..<0.45: return .medium
        case 0.45..<0.6: return .large
        case 0.6..<0.75: return .xLarge
        case 0.75..<0.9: return .xxLarge
        default: return .xxxLarge
        }
    }
}

// MARK: - Accessibility Environment Key
struct AccessibilitySettingsKey: EnvironmentKey {
    static let defaultValue = AccessibilitySettings()
}

extension EnvironmentValues {
    var accessibilitySettings: AccessibilitySettings {
        get { self[AccessibilitySettingsKey.self] }
        set { self[AccessibilitySettingsKey.self] = newValue }
    }
}

// MARK: - Global Accessibility Modifier
struct GlobalAccessibilityModifier: ViewModifier {
    @ObservedObject var settings = AccessibilitySettings.shared

    func body(content: Content) -> some View {
        content
            .environment(\.accessibilitySettings, settings)
            .environment(\.dynamicTypeSize, settings.getDynamicTypeSize())
    }
}

// MARK: - Text Size Modifier
struct ScaledTextModifier: ViewModifier {
    @ObservedObject var settings = AccessibilitySettings.shared
    var baseSize: CGFloat
    var weight: Font.Weight
    var design: Font.Design
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: settings.getScaledFontSize(baseSize), weight: weight, design: design))
    }
}

// MARK: - View Extensions
extension View {
    func withGlobalAccessibilitySettings() -> some View {
        self.modifier(GlobalAccessibilityModifier())
    }
    
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        self.modifier(ScaledTextModifier(baseSize: size, weight: weight, design: design))
    }
    
    func speakOnAppear(_ text: String) -> some View {
        self.modifier(VoiceOverNarratorModifier(text: text))
    }
}

// MARK: - Voice Over Narrator Modifier
struct VoiceOverNarratorModifier: ViewModifier {
    let text: String
    @ObservedObject var settings = AccessibilitySettings.shared

    func body(content: Content) -> some View {
        content
            .onAppear {
                if settings.isVoiceOver {
                    VoiceOverManager.shared.speak(text)
                }
            }
    }
}
