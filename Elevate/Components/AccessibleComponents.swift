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
            .foregroundColor(settings.isHighContrast ? .white : .gray)
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

// MARK: - Accessible Toggle Row
struct AccessToggleRow: View {
    var title: String
    var desc: String
    var icon: String
    @Binding var isOn: Bool
    
    @ObservedObject private var settings = AccessibilitySettings.shared
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(settings.isHighContrast ? Color.white.opacity(0.2) : Color.elevateDarkGreen.opacity(0.1))
                    .frame(width: 38, height: 38)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(settings.isHighContrast ? .white : .elevateDarkGreen)
            }
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(settings.isHighContrast ? .white : .black)
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundColor(settings.isHighContrast ? .white : .elevateTextGray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isOn },
                set: { newValue in
                    isOn = newValue
                    HapticManager.shared.playSelection()
                }
            ))
            .tint(.elevateDarkGreen)
            .labelsHidden()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint(desc)
    }
}
