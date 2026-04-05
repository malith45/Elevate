import SwiftUI

struct TechnicianCalendarView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab: TechnicianDashboardView.TabItem = .dashboard
    
    // Using a simple array for the demo grid layout
    let days = [
        ("30", false, false), ("1", true, false), ("2", false, false), ("3", true, false),
        ("4", false, false), ("5", false, false), ("6", false, false), ("7", false, false),
        ("8", false, false), ("9", true, false), ("10", false, false), ("11", false, true),
        ("12", false, false), ("13", false, false), ("14", true, false), ("15", false, false),
        ("16", false, false), ("17", false, false), ("18", false, false), ("19", false, false),
        ("20", false, false), ("21", false, false), ("22", false, false), ("23", false, false),
        ("24", false, false), ("25", false, false), ("26", false, false), ("27", false, false),
        ("28", false, false)
    ]
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Calendar Header
                        HStack {
                            Text("October 2024")
                                .scaledFont(size: 24, weight: .bold, design: .rounded)
                            
                            Spacer()
                            
                            HStack(spacing: 24) {
                                Image(systemName: "chevron.left")
                                Image(systemName: "chevron.right")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.elevateDarkGreen)
                        }
                        .padding(.horizontal, 24)
                        
                        // Today Badge
                        Text("Today")
                            .scaledFont(size: 14, weight: .medium)
                            .foregroundColor(.elevateDarkGreen)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.elevateDarkGreen.opacity(0.1))
                            .cornerRadius(16)
                            .padding(.horizontal, 24)
                        
                        // Calendar Grid
                        VStack(spacing: 16) {
                            // Days of week
                            HStack {
                                ForEach(["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"], id: \.self) { day in
                                    Text(day)
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(.elevateTextGray)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            
                            // Dates
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(0..<days.count, id: \.self) { i in
                                    let item = days[i]
                                    VStack(spacing: 4) {
                                        Text(item.0)
                                            .scaledFont(size: 16)
                                            .foregroundColor(item.0 == "30" ? .elevateTextGray : (item.2 ? .white : .black))
                                            .frame(width: 32, height: 32)
                                            .background(item.2 ? Color.elevateDarkGreen : Color.clear)
                                            .cornerRadius(16)
                                        
                                        Circle()
                                            .fill(item.1 ? Color.elevateDarkGreen : Color.clear)
                                            .frame(width: 4, height: 4)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Divider().padding(.vertical, 8)
                        
                        // Jobs List
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("FRIDAY, OCT 11")
                                    .scaledFont(size: 12, weight: .bold)
                                    .foregroundColor(.elevateTextGray)
                                
                                Spacer()
                                
                                Text("2 JOBS")
                                    .scaledFont(size: 10, weight: .bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.elevateDarkGreen.opacity(0.1))
                                    .foregroundColor(.elevateDarkGreen)
                                    .cornerRadius(8)
                            }
                            
                            VStack(spacing: 24) {
                                JobCalendarRow(time: "09:00", ampm: "AM", title: "HVAC System Calibration", location: "Lexington Towers, Suite 405", dotColor: .elevateDarkGreen)
                                JobCalendarRow(time: "11:30", ampm: "AM", title: "Routine Filter Change", location: "Northside Corporate Park", dotColor: .elevateLightGray)
                            }
                            
                            Spacer().frame(height: 32)
                            
                            HStack {
                                Spacer()
                                Text("No more jobs scheduled for today")
                                    .scaledFont(size: 14)
                                    .foregroundColor(.elevateTextGray)
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer().frame(height: 100)
                    }
                }
            }
            
            // Bottom Navbar Floating
            ReusableBottomNav(selectedTab: .constant(.dashboard))
        }
        .navigationBarHidden(true)
    }
}

struct JobCalendarRow: View {
    var time: String
    var ampm: String
    var title: String
    var location: String
    var dotColor: Color
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(spacing: 2) {
                Text(time)
                    .scaledFont(size: 14, weight: .bold)
                Text(ampm)
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundColor(.elevateTextGray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .scaledFont(size: 16, weight: .bold)
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 10))
                    Text(location)
                        .scaledFont(size: 12)
                }
                .foregroundColor(.elevateTextGray)
            }
            Spacer()
            
            HStack(spacing: 8) {
                Circle().fill(dotColor).frame(width: 8, height: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.elevateTextGray)
            }
        }
    }
}

#Preview {
    TechnicianCalendarView()
}
