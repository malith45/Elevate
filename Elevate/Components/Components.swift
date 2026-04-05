import SwiftUI

struct CustomTextField: View {
    var title: String
    var placeholder: String
    var iconName: String
    @Binding var text: String
    var titleAction: AnyView? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.elevateTextGray)
                    .textCase(.uppercase)
                
                Spacer()
                
                if let titleAction = titleAction {
                    titleAction
                }
            }
            
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(.elevateTextGray)
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .autocapitalization(.none)
            }
            .padding()
            .background(Color.elevateLightGray)
            .cornerRadius(10)
        }
    }
}

struct SecureCustomTextField: View {
    var title: String
    var placeholder: String
    var iconName: String
    @Binding var text: String
    var titleAction: AnyView? = nil
    
    @State private var isSecure = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.elevateTextGray)
                    .textCase(.uppercase)
                
                Spacer()
                
                if let titleAction = titleAction {
                    titleAction
                }
            }
            
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(.elevateTextGray)
                    .frame(width: 20)
                
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                } else {
                    TextField(placeholder, text: $text)
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .autocapitalization(.none)
                }
                
                Button(action: {
                    isSecure.toggle()
                }) {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .foregroundColor(.elevateTextGray)
                }
            }
            .padding()
            .background(Color.elevateLightGray)
            .cornerRadius(10)
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
            .font(.system(size: 16, weight: .bold))
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
            .font(.system(size: 16, weight: .bold))
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
