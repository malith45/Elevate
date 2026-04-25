import SwiftUI

struct NotificationCard: View {
    var item: NotificationItem
    var onTap: (() -> Void)?
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon based on type
            ZStack {
                Circle()
                    .fill(settings.isHighContrast ? Color.black : iconBackgroundColor)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle().stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: settings.isHighContrast ? 2 : 0)
                    )
                
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(settings.isHighContrast ? .white : iconForegroundColor)
            }
            .padding(.leading, 12)
            .padding(.vertical, 16)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(item.title)
                        .scaledFont(size: 16, weight: .bold)
                        .foregroundColor(settings.primaryText)
                    Spacer()
                    Text(timeAgo(from: item.createdAt))
                        .scaledFont(size: 10, weight: .bold)
                        .foregroundColor(settings.secondaryText)
                }
                
                Text(item.body)
                    .scaledFont(size: 14)
                    .foregroundColor(settings.secondaryText)
                    .lineLimit(2)
            }
            .padding(.vertical, 16)
            
            // Unread Indicator
            if !item.isRead {
                Circle()
                    .fill(settings.accentColor)
                    .frame(width: 8, height: 8)
                    .padding(.trailing, 12)
                    .padding(.top, 20)
            }
        }
        .background(settings.surfaceColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }

    private var iconName: String {
        let type = item.type.uppercased()
        if type.contains("JOB") { return "briefcase.fill" }
        if type.contains("QUOTE") { return "doc.text.fill" }
        if type.contains("ISSUE") { return "exclamationmark.triangle.fill" }
        if type.contains("INVENTORY") { return "shippingbox.fill" }
        return "bell.fill"
    }
    
    private var iconBackgroundColor: Color {
        let type = item.type.uppercased()
        if type.contains("JOB") { return Color.blue.opacity(0.1) }
        if type.contains("QUOTE") { return Color.orange.opacity(0.1) }
        if type.contains("ISSUE") { return Color.red.opacity(0.1) }
        if type.contains("INVENTORY") { return Color.purple.opacity(0.1) }
        return settings.accentColor.opacity(0.1)
    }
    
    private var iconForegroundColor: Color {
        let type = item.type.uppercased()
        if type.contains("JOB") { return .blue }
        if type.contains("QUOTE") { return .orange }
        if type.contains("ISSUE") { return .red }
        if type.contains("INVENTORY") { return .purple }
        return settings.accentColor
    }

    private func timeAgo(from date: Date) -> String {
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        if minutes < 60 {
            return "\(max(minutes, 1))m ago"
        }
        let hours = minutes / 60
        if hours < 24 {
            return "\(hours)h ago"
        }
        let days = hours / 24
        return "\(days)d ago"
    }
}

struct NotificationSection: View {
    let title: String
    let items: [NotificationItem]
    var onTap: ((NotificationItem) -> Void)?
    @ObservedObject var settings = AccessibilitySettings.shared

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundColor(settings.secondaryText)
                    .padding(.horizontal, 24)

                ForEach(items) { item in
                    NotificationCard(item: item, onTap: {
                        onTap?(item)
                    })
                }
            }
        }
    }
}

struct InAppNotificationToast: View {
    let notification: NotificationItem
    var onDismiss: () -> Void
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(settings.isHighContrast ? Color.black : settings.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle().stroke(settings.isHighContrast ? settings.primaryText : Color.clear, lineWidth: settings.isHighContrast ? 2 : 0)
                    )
                
                Image(systemName: iconName(for: notification.type))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(settings.isHighContrast ? settings.primaryText : settings.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .scaledFont(size: 14, weight: .bold)
                    .foregroundColor(settings.primaryText)
                
                Text(notification.body)
                    .scaledFont(size: 13)
                    .foregroundColor(settings.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(settings.secondaryText)
                    .padding(8)
                    .background(Circle().fill(settings.isHighContrast ? Color.white.opacity(0.2) : Color.black.opacity(0.05)))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(settings.surfaceColor)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private func iconName(for type: String) -> String {
        switch type {
        case "JOB_ASSIGNED", "JOB_CANCELLED", "JOB_STARTED", "JOB_HOLD", "JOB_COMPLETED":
            return "briefcase.fill"
        case "QUOTE_SUBMITTED", "QUOTE_APPROVED", "QUOTE_REJECTED":
            return "doc.text.fill"
        case "ISSUE_REPORTED":
            return "exclamationmark.triangle.fill"
        case "CRITICAL_INVENTORY":
            return "shippingbox.fill"
        default:
            return "bell.fill"
        }
    }
}
