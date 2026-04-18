import SwiftUI

struct CustomTextField: View {
    var title: String
    var placeholder: String
    var iconName: String
    @Binding var text: String
    var errorMessage: String? = nil
    var titleAction: AnyView? = nil
    
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
                
                TextField(placeholder, text: $text)
                    .scaledFont(size: 15)
                    .foregroundColor(.black)
                    .autocapitalization(.none)
                    .focused($isFocused)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.elevateLightGray.opacity(isFocused ? 0.5 : 1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        errorMessage != nil ? Color.red : (isFocused ? Color.elevateDarkGreen : Color.clear),
                        lineWidth: 1.5
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
                .foregroundColor(.black)
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
                    .fill(Color.elevateLightGray.opacity(isFocused ? 0.5 : 1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        errorMessage != nil ? Color.red : (isFocused ? Color.elevateDarkGreen : Color.clear),
                        lineWidth: 1.5
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
            .background(Color.elevateDarkGreen)
            .cornerRadius(10)
            .shadow(color: Color.elevateDarkGreen.opacity(0.3), radius: 5, x: 0, y: 3)
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
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.elevateLightGray, lineWidth: 1)
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
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 24)
    }
}
