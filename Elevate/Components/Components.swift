import SwiftUI

struct CustomTextField: View {
    var title: String
    var placeholder: String
    var iconName: String
    @Binding var text: String
    var errorMessage: String? = nil
    var titleAction: AnyView? = nil
    
    @FocusState private var isFocused: Bool
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .scaledFont(size: 11, weight: .bold)
                    .foregroundColor(errorMessage != nil ? .red : settings.secondaryText)
                    .textCase(.uppercase)
                
                Spacer()
                
                if let titleAction = titleAction {
                    titleAction
                }
            }
            .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .foregroundColor(errorMessage != nil ? .red : (isFocused ? settings.accentColor : settings.secondaryText))
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .scaledFont(size: 15)
                    .foregroundColor(settings.primaryText)
                    .autocapitalization(.none)
                    .focused($isFocused)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(settings.surfaceColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        errorMessage != nil ? Color.red : (isFocused ? settings.accentColor : settings.cardStroke),
                        lineWidth: settings.cardStrokeWidth
                    )
            )
            .shadow(color: isFocused ? settings.accentColor.opacity(0.1) : Color.clear, radius: 8, x: 0, y: 4)
            
            if let error = errorMessage {
                Text(error)
                    .scaledFont(size: 10, weight: .medium)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
                    .transition(.opacity)
            }
        }
    }
}

struct CustomTextEditor: View {
    var title: String
    var placeholder: String
    var iconName: String
    @Binding var text: String
    
    @FocusState private var isFocused: Bool
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .scaledFont(size: 11, weight: .bold)
                    .foregroundColor(settings.secondaryText)
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: iconName)
                    .foregroundColor(isFocused ? settings.accentColor : settings.secondaryText)
                    .frame(width: 20)
                    .padding(.top, 12)
                
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .scaledFont(size: 15)
                            .foregroundColor(settings.secondaryText.opacity(0.5))
                            .padding(.top, 12)
                            .padding(.leading, 4)
                    }
                    
                    TextEditor(text: $text)
                        .scaledFont(size: 15)
                        .foregroundColor(settings.primaryText)
                        .frame(minHeight: 120)
                        .focused($isFocused)
                        .scrollContentBackground(.hidden)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(settings.surfaceColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isFocused ? settings.accentColor : settings.cardStroke,
                        lineWidth: settings.cardStrokeWidth
                    )
            )
            .shadow(color: isFocused ? settings.accentColor.opacity(0.1) : Color.clear, radius: 8, x: 0, y: 4)
        }
    }
}

struct SecureCustomTextField: View {
    var title: String
    var placeholder: String
    var iconName: String
    @Binding var text: String
    var errorMessage: String? = nil
    var titleAction: AnyView? = nil
    
    @State private var isSecure = true
    @FocusState private var isFocused: Bool
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .scaledFont(size: 11, weight: .bold)
                    .foregroundColor(errorMessage != nil ? .red : settings.secondaryText)
                    .textCase(.uppercase)
                
                Spacer()
                
                if let titleAction = titleAction {
                    titleAction
                }
            }
            .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .foregroundColor(errorMessage != nil ? .red : (isFocused ? settings.accentColor : settings.secondaryText))
                    .frame(width: 20)
                
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                            .autocapitalization(.none)
                    }
                }
                .scaledFont(size: 15)
                .foregroundColor(settings.primaryText)
                .focused($isFocused)
                
                Button(action: {
                    isSecure.toggle()
                    HapticManager.shared.playImpact(style: .light)
                }) {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .font(.system(size: 14))
                        .foregroundColor(settings.secondaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(settings.surfaceColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        errorMessage != nil ? Color.red : (isFocused ? settings.accentColor : settings.cardStroke),
                        lineWidth: settings.cardStrokeWidth
                    )
            )
            .shadow(color: isFocused ? settings.accentColor.opacity(0.1) : Color.clear, radius: 8, x: 0, y: 4)
            
            if let error = errorMessage {
                Text(error)
                    .scaledFont(size: 10, weight: .medium)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
                    .transition(.opacity)
            }
        }
    }
}

struct PrimaryButton: View {
    var title: String
    var iconName: String?
    var action: () -> Void
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        Button(action: {
            HapticManager.shared.playImpact(style: .medium)
            action()
        }) {
            HStack(spacing: 10) {
                Text(title)
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .scaledFont(size: 16, weight: .bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(settings.accentColor)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
            )
            .shadow(color: settings.isHighContrast ? .clear : settings.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryButton: View {
    var title: String
    var iconName: String?
    var action: () -> Void
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        Button(action: {
            HapticManager.shared.playImpact(style: .light)
            action()
        }) {
            HStack(spacing: 10) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .foregroundColor(settings.accentColor)
                        .font(.system(size: 14, weight: .bold))
                }
                Text(title)
                    .foregroundColor(settings.primaryText)
            }
            .scaledFont(size: 16, weight: .bold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(settings.surfaceColor)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
            )
        }
        .buttonStyle(.plain)
    }
}

struct EmptyStateView: View {
    var title: String
    var message: String
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray.fill")
                .font(.system(size: 48))
                .foregroundColor(settings.secondaryText.opacity(0.2))
            
            VStack(spacing: 8) {
                Text(title)
                    .scaledFont(size: 18, weight: .bold)
                    .foregroundColor(settings.primaryText)
                Text(message)
                    .scaledFont(size: 14)
                    .foregroundColor(settings.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(settings.surfaceColor)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 24)
    }
}

struct PasswordRequirementsView: View {
    let password: String
    @ObservedObject var settings = AccessibilitySettings.shared
 
    private struct Requirement {
        let label: String
        let isMet: Bool
    }
 
    private var requirements: [Requirement] {
        [
            Requirement(label: "At least 8 characters", isMet: password.count >= 8),
            Requirement(label: "One uppercase letter (A–Z)", isMet: password.range(of: "[A-Z]", options: .regularExpression) != nil),
            Requirement(label: "One lowercase letter (a–z)", isMet: password.range(of: "[a-z]", options: .regularExpression) != nil),
            Requirement(label: "One digit (0–9)", isMet: password.range(of: "[0-9]", options: .regularExpression) != nil),
            Requirement(label: "One special character (!@#$…)", isMet: password.range(of: "[!@#$%^&*()\\-_=+{}|;:'\",.<>/?]", options: .regularExpression) != nil)
        ]
    }
 
    var body: some View {
        if !password.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("PASSWORD REQUIREMENTS")
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundColor(settings.secondaryText)
                    .padding(.horizontal, 4)
 
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(requirements, id: \.label) { req in
                        HStack(spacing: 10) {
                            Image(systemName: req.isMet ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(req.isMet ? settings.accentColor : settings.secondaryText.opacity(0.3))
                            Text(req.label)
                                .scaledFont(size: 12, weight: .medium)
                                .foregroundColor(req.isMet ? settings.primaryText : settings.secondaryText.opacity(0.7))
                        }
                    }
                }
                .padding(16)
                .background(settings.surfaceColor)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                )
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}
