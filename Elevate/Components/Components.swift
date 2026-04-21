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
                    .foregroundColor(errorMessage != nil ? .red : .elevateTextGray)
                    .textCase(.uppercase)
                
                Spacer()
                
                if let titleAction = titleAction {
                    titleAction
                }
            }
            .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .foregroundColor(errorMessage != nil ? .red : (isFocused ? .elevateDarkGreen : .elevateTextGray))
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
            .shadow(color: isFocused ? Color.elevateDarkGreen.opacity(0.1) : Color.clear, radius: 8, x: 0, y: 4)
            
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

struct SecureCustomTextField: View {
    var title: String
    var placeholder: String
    var iconName: String
    @Binding var text: String
    var errorMessage: String? = nil
    var titleAction: AnyView? = nil
    
    @State private var isSecure = true
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .scaledFont(size: 11, weight: .bold)
                    .foregroundColor(errorMessage != nil ? .red : .elevateTextGray)
                    .textCase(.uppercase)
                
                Spacer()
                
                if let titleAction = titleAction {
                    titleAction
                }
            }
            .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .foregroundColor(errorMessage != nil ? .red : (isFocused ? .elevateDarkGreen : .elevateTextGray))
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
                .foregroundColor(AccessibilitySettings.shared.primaryText)
                .focused($isFocused)
                
                Button(action: {
                    isSecure.toggle()
                }) {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .font(.system(size: 14))
                        .foregroundColor(.elevateTextGray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AccessibilitySettings.shared.surfaceColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        errorMessage != nil ? Color.red : (isFocused ? AccessibilitySettings.shared.accentColor : AccessibilitySettings.shared.cardStroke),
                        lineWidth: AccessibilitySettings.shared.cardStrokeWidth
                    )
            )
            .shadow(color: isFocused ? Color.elevateDarkGreen.opacity(0.1) : Color.clear, radius: 8, x: 0, y: 4)
            
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
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                if let iconName = iconName {
                    Image(systemName: iconName)
                }
            }
            .scaledFont(size: 16, weight: .bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AccessibilitySettings.shared.isHighContrast ? AccessibilitySettings.shared.surfaceColor : Color.elevateDarkGreen)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AccessibilitySettings.shared.cardStroke, lineWidth: AccessibilitySettings.shared.cardStrokeWidth)
            )
            .shadow(color: AccessibilitySettings.shared.isHighContrast ? .clear : Color.elevateDarkGreen.opacity(0.3), radius: 5, x: 0, y: 3)
        }
    }
}

struct SecondaryButton: View {
    var title: String
    var iconName: String?
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .foregroundColor(.elevateDarkGreen)
                }
                Text(title)
                    .foregroundColor(.black)
            }
            .scaledFont(size: 16, weight: .bold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AccessibilitySettings.shared.isHighContrast ? AccessibilitySettings.shared.surfaceColor : Color.white)
            .cornerRadius(10)
            .shadow(color: AccessibilitySettings.shared.isHighContrast ? .clear : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AccessibilitySettings.shared.cardStroke, lineWidth: AccessibilitySettings.shared.cardStrokeWidth)
            )
        }
    }
}

struct EmptyStateView: View {
    var title: String
    var message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .scaledFont(size: 18, weight: .bold)
            Text(message)
                .scaledFont(size: 14)
                .foregroundColor(.elevateTextGray)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(AccessibilitySettings.shared.surfaceColor)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AccessibilitySettings.shared.cardStroke, lineWidth: AccessibilitySettings.shared.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 24)
    }
}

struct PasswordRequirementsView: View {
    let password: String

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
            VStack(alignment: .leading, spacing: 6) {
                Text("PASSWORD REQUIREMENTS")
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundColor(.elevateTextGray)
                    .padding(.horizontal, 4)

                VStack(alignment: .leading, spacing: 5) {
                    ForEach(requirements, id: \.label) { req in
                        HStack(spacing: 8) {
                            Image(systemName: req.isMet ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(req.isMet ? .elevateDarkGreen : Color.elevateTextGray.opacity(0.4))
                                .animation(.easeInOut(duration: 0.2), value: req.isMet)
                            Text(req.label)
                                .scaledFont(size: 12)
                                .foregroundColor(req.isMet ? .elevateDarkGreen : Color.elevateTextGray.opacity(0.7))
                                .animation(.easeInOut(duration: 0.2), value: req.isMet)
                        }
                    }
                }
                .padding(12)
                .background(Color.elevateLightGray.opacity(0.5))
                .cornerRadius(10)
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
            .animation(.easeInOut(duration: 0.2), value: password.isEmpty)
        }
    }
}
