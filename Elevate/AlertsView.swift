import SwiftUI

struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let time: String
    let icon: String
    let iconColor: Color
    let iconBgColor: Color
    let isUnread: Bool
    let hasCardBackground: Bool
}

struct AlertsView: View {
    @Binding var showAlerts: Bool
    
    // Colors
    let bgColor = Color(red: 15/255, green: 23/255, blue: 42/255) // #0F172A
    let primaryText = Color(red: 248/255, green: 250/255, blue: 252/255) // #F8FAFC
    let secBgColor = Color(red: 30/255, green: 41/255, blue: 59/255) // #1E293B
    let secTextColor = Color(red: 203/255, green: 213/255, blue: 245/255) // #CBD5F5
    let linkColor = Color(red: 14/255, green: 165/255, blue: 233/255) // #0EA5E9
    let unreadDotColor = Color(red: 59/255, green: 130/255, blue: 246/255) // #3B82F6
    
    let todayAlerts: [AlertItem] = [
        AlertItem(title: "New Job Assigned", message: "RE-8493: Routine Elevator\nMaintenance has been assigned to you.", time: "10m ago", icon: "calendar", iconColor: Color(red: 14/255, green: 165/255, blue: 233/255), iconBgColor: Color(red: 14/255, green: 165/255, blue: 233/255).opacity(0.15), isUnread: true, hasCardBackground: true),
        AlertItem(title: "Costing Approved", message: "Manager approved LKR 25,000 for\nIndustrial Capacitor on RE-8492.", time: "1h ago", icon: "dollarsign", iconColor: Color(red: 16/255, green: 185/255, blue: 129/255), iconBgColor: Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.15), isUnread: true, hasCardBackground: true)
    ]
    
    let yesterdayAlerts: [AlertItem] = [
        AlertItem(title: "Emergency Alert", message: "JOB-8490: Water Leak in Lobby\nrequires immediate attention.", time: "Yesterday", icon: "exclamationmark.triangle", iconColor: Color(red: 239/255, green: 68/255, blue: 68/255), iconBgColor: Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.15), isUnread: false, hasCardBackground: false),
        AlertItem(title: "Schedule Updated", message: "Your shift tomorrow starts at 09:00 AM.", time: "Yesterday", icon: "bell", iconColor: .white, iconBgColor: Color.white.opacity(0.15), isUnread: false, hasCardBackground: false)
    ]

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                ZStack {
                    Text("Alerts")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryText)
                    
                    HStack {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.25)) { 
                                showAlerts = false 
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundColor(primaryText)
                                .padding(.leading, 24)
                        }
                        Spacer()
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // TODAY SECTION
                        HStack {
                            Text("Today")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(primaryText)
                            Spacer()
                            Button("Clear All") {
                                // Clear action
                            }
                            .font(.footnote)
                            .foregroundColor(linkColor)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                        
                        VStack(spacing: 12) {
                            ForEach(todayAlerts) { alert in
                                AlertRow(alert: alert, secBgColor: secBgColor, primaryText: primaryText, secTextColor: secTextColor, unreadDotColor: unreadDotColor)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // YESTERDAY SECTION
                        Text("Yesterday")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(primaryText)
                            .padding(.horizontal, 24)
                            .padding(.top, 10)
                        
                        VStack(spacing: 0) {
                            ForEach(yesterdayAlerts) { alert in
                                AlertRow(alert: alert, secBgColor: secBgColor, primaryText: primaryText, secTextColor: secTextColor, unreadDotColor: unreadDotColor)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 120) // Give generous space for the floating bottom navigation bar
                }
            }
        }
    }
}

struct AlertRow: View {
    let alert: AlertItem
    let secBgColor: Color
    let primaryText: Color
    let secTextColor: Color
    let unreadDotColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Unread Dot
            Circle()
                .fill(alert.isUnread ? unreadDotColor : Color.clear)
                .frame(width: 8, height: 8)
                .padding(.top, 18)
            
            // Icon
            Circle()
                .fill(alert.iconBgColor)
                .frame(width: 46, height: 46)
                .overlay(
                    Image(systemName: alert.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(alert.iconColor)
                )
            
            // Text Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(alert.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryText)
                    Spacer()
                    Text(alert.time)
                        .font(.caption2)
                        .foregroundColor(secTextColor)
                }
                
                Text(alert.message)
                    .font(.footnote)
                    .foregroundColor(secTextColor)
                    .lineSpacing(2)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 16)
        .padding(.trailing, 16)
        .padding(.leading, alert.hasCardBackground ? 8 : 8)
        .background(alert.hasCardBackground ? RoundedRectangle(cornerRadius: 12).fill(secBgColor) : RoundedRectangle(cornerRadius: 12).fill(Color.clear))
    }
}

#Preview {
    AlertsView(showAlerts: .constant(true))
}
