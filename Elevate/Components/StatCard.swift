import SwiftUI

struct StatCard: View {
    var icon: String
    var title: String
    var value: String
    var subtitle: String
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(settings.accentColor)
                .padding(10)
                .background(settings.isHighContrast ? settings.surfaceColor : settings.accentColor.opacity(0.1))
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(settings.primaryText, lineWidth: settings.isHighContrast ? 1.5 : 0)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .scaledFont(size: 24, weight: .bold, design: .rounded)
                    .foregroundColor(settings.primaryText)
                
                Text(title)
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundColor(settings.secondaryText)
                    .tracking(0.5)
                    .textCase(.uppercase)
            }
            
            Text(subtitle)
                .scaledFont(size: 11)
                .foregroundColor(settings.secondaryText.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(settings.surfaceColor)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    HStack {
        StatCard(icon: "briefcase.fill", title: "JOBS DONE", value: "12", subtitle: "Total work")
        StatCard(icon: "target", title: "EFFICIENCY", value: "95%", subtitle: "Organization")
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
