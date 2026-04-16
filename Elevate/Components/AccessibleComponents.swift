import SwiftUI

// MARK: - Accessible Text Components
struct AccessibleHeading: View {
    let text: String
    let size: CGFloat
    let weight: Font.Weight
    
    @ObservedObject private var settings = AccessibilitySettings.shared
    
    var body: some View {
        Text(text)
            .font(.system(size: settings.getScaledFontSize(size), weight: weight, design: .rounded))
            .foregroundColor(settings.isHighContrast ? .white : .black)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(text)
    }
}

struct AccessibleBody: View {
    let text: String
    let size: CGFloat
    let color: Color = .black
    
    @ObservedObject private var settings = AccessibilitySettings.shared
    
    var body: some View {
        Text(text)
            .font(.system(size: settings.getScaledFontSize(size)))
            .foregroundColor(settings.isHighContrast ? .white : color)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(text)
    }
}

struct AccessibleCaption: View {
    let text: String
    let size: CGFloat
    
    @ObservedObject private var settings = AccessibilitySettings.shared
    
    var body: some View {
        Text(text)
            .font(.system(size: settings.getScaledFontSize(size)))
            .foregroundColor(settings.isHighContrast ? Color.gray.opacity(0.7) : .gray)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(text)
    }
}

// MARK: - Accessible Button Wrapper
struct AccessibleButton: View {
    let label: String
    let action: () -> Void
    let style: ButtonStyle
    
    @ObservedObject private var settings = AccessibilitySettings.shared
    
    enum ButtonStyle {
        case primary
        case secondary
        case tertiary
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.playSelection()
            action()
        }) {
            Text(label)
                .font(.system(size: settings.getScaledFontSize(14), weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(backgroundColor)
                .foregroundColor(textColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(settings.isHighContrast ? .black : .clear, lineWidth: 2)
                )
        }
        .accessibilityLabel(label)
        .accessibilityHint("Double tap to activate")
        .accessibilityAddTraits(.isButton)
    }
    
    private var backgroundColor: Color {
        if settings.isHighContrast {
            switch style {
            case .primary: return .black
            case .secondary: return .white
            case .tertiary: return .clear
            }
        }
        switch style {
        case .primary:
            return .elevateDarkGreen
        case .secondary:
            return Color.elevateLightGray
        case .tertiary:
            return Color.clear
        }
    }
    
    private var textColor: Color {
        if settings.isHighContrast {
            switch style {
            case .primary: return .white
            case .secondary: return .black
            case .tertiary: return .black
            }
        }
        switch style {
        case .primary:
            return .white
        case .secondary:
            return .elevateDarkGreen
        case .tertiary:
            return .elevateDarkGreen
        }
    }
}

// MARK: - Accessible Card
struct AccessibleCard<Content: View>: View {
    let content: Content
    
    @ObservedObject private var settings = AccessibilitySettings.shared
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background(settings.isHighContrast ? Color.black : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        settings.isHighContrast ? Color.white : Color.clear,
                        lineWidth: settings.isHighContrast ? 3 : 0
                    )
            )
            .accessibilityElement(children: .contain)
    }
}
