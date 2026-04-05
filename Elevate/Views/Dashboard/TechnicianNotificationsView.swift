import SwiftUI

struct TechnicianNotificationsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab: TechnicianDashboardView.TabItem = .dashboard
    
    var body: some View {
        ZStack {
            Color.elevateLightGray.opacity(0.3).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Header
                        HStack {
                            Text("Notifications")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                            Spacer()
                            Text("Clear All")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.elevateDarkGreen)
                        }
                        .padding(.horizontal, 24)
                        
                        // TODAY
                        VStack(alignment: .leading, spacing: 16) {
                            Text("TODAY")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.elevateTextGray)
                                .padding(.horizontal, 24)
                            
                            NotificationCard(
                                title: "New Job Assigned",
                                message: "Maintenance has been assigned to you at 442 Park Avenue. Emergency repair required.",
                                timeAgo: "12M AGO",
                                isUnread: true
                            )
                            
                            NotificationCard(
                                title: "Shift Starting Soon",
                                message: "Your evening shift starts in 15 minutes. Remember to clock in via the dashboard.",
                                timeAgo: "45M AGO",
                                isUnread: false
                            )
                            
                            NotificationCard(
                                title: "Report Approved",
                                message: "Your inspection report for 'Skyline Plaza' has been reviewed and approved by the supervisor.",
                                timeAgo: "2H AGO",
                                isUnread: true
                            )
                        }
                        
                        // YESTERDAY
                        VStack(alignment: .leading, spacing: 16) {
                            Text("YESTERDAY")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.elevateTextGray)
                                .padding(.horizontal, 24)
                            
                            NotificationCard(
                                title: "Payment Dispatched",
                                message: "Your weekly earnings of $1,240.50 have been sent to your primary bank account.",
                                timeAgo: "1D AGO",
                                isUnread: false
                            )
                            
                            NotificationCard(
                                title: "Inventory Restocked",
                                message: "The requested HVAC components have been delivered to the central locker station.",
                                timeAgo: "1D AGO",
                                isUnread: false
                            )
                            
                            NotificationCard(
                                title: "New Message",
                                message: "David M. left a comment on your latest maintenance ticket: \"Great job on the filter replacement.\"",
                                timeAgo: "1D AGO",
                                isUnread: false
                            )
                        }
                        
                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 16)
                }
            }
            
            // Bottom Navbar Floating
            ReusableBottomNav(selectedTab: .constant(.dashboard))
        }
        .navigationBarHidden(true)
    }
}

struct NotificationCard: View {
    var title: String
    var message: String
    var timeAgo: String
    var isUnread: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Unread Indicator Bar
            Rectangle()
                .fill(isUnread ? Color.elevateDarkGreen : Color.clear)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                    HStack(spacing: 8) {
                        Text(timeAgo)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.elevateTextGray)
                        
                        if isUnread {
                            Circle()
                                .fill(Color.elevateDarkGreen)
                                .frame(width: 8, height: 8)
                        } else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 8, height: 8) // spacing preservation
                        }
                    }
                }
                
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(Color.gray)
                    .lineSpacing(4)
            }
            .padding(.vertical, 16)
            .padding(.trailing, 16)
        }
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 24)
    }
}

#Preview {
    TechnicianNotificationsView()
}
