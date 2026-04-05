import SwiftUI
import Charts

struct TechnicianDashboardView: View {
    @State private var selectedTab: TabItem = .dashboard
    
    enum TabItem {
        case dashboard, jobs, map, profile
    }
    
    // Sample Data
    let performanceData = [
        (day: "MON", value: 20),
        (day: "TUE", value: 30),
        (day: "WED", value: 25),
        (day: "THU", value: 45),
        (day: "FRI", value: 50),
        (day: "SAT", value: 35),
        (day: "SUN", value: 15)
    ]
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                BrandHeaderNav(showOnlineStatus: true)
                
                // Content Spacer
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Header text
                        VStack(alignment: .leading, spacing: 4) {
                            Text("THURSDAY, OCT 24")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.elevateTextGray)
                            
                            Text("Good morning, Marcus")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                        }
                        
                        // Urgent Update Banner
                        HStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("URGENT UPDATE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.8))
                                Text("New high-priority job assigned in Soho")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.elevateDarkGreen)
                        .cornerRadius(12)
                        
                        // Weekly Performance Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("WEEKLY PERFORMANCE")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.elevateTextGray)
                                    
                                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                                        Text("42")
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.elevateDarkGreen)
                                        Text("Jobs Completed")
                                            .font(.system(size: 14))
                                            .foregroundColor(.elevateTextGray)
                                    }
                                }
                                Spacer()
                                HStack(spacing: 2) {
                                    Image(systemName: "arrow.up.right")
                                    Text("12%")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green)
                            }
                            
                            Chart(performanceData, id: \.day) { item in
                                BarMark(
                                    x: .value("Day", item.day),
                                    y: .value("Value", item.value)
                                )
                                .foregroundStyle(item.day == "FRI" ? Color.elevateDarkGreen : Color.elevateDarkGreen.opacity(0.4))
                                .cornerRadius(4)
                            }
                            .frame(height: 100)
                            .chartXAxis {
                                AxisMarks { value in
                                    AxisValueLabel {
                                        if let day = value.as(String.self) {
                                            Text(day)
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.elevateTextGray)
                                        }
                                    }
                                }
                            }
                            .chartYAxis(.hidden)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)
                        
                        // Shortcuts
                        HStack(spacing: 16) {
                            ShortcutBox(title: "START JOB", icon: "play.fill", dest: EmptyView())
                            NavigationLink(destination: TechnicianCalendarView()) {
                                ShortcutBoxInternal(title: "CALENDAR", icon: "calendar")
                            }
                            NavigationLink(destination: TechnicianStatisticsView()) {
                                ShortcutBoxInternal(title: "STATISTICS", icon: "chart.bar.fill")
                            }
                        }
                        
                        // Today's Tasks
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("TODAY'S TASKS")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.elevateTextGray)
                                Spacer()
                                Text("View All")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.elevateDarkGreen)
                            }
                            
                            VStack(spacing: 16) {
                                TaskRow(time: "09:22", ampm: "AM", title: "HVAC System Calibration", location: "Lexington Towers, Suite 405", priority: "HIGH PRIORITY", color: .red)
                                TaskRow(time: "11:32", ampm: "AM", title: "Routine Filter Change", location: "Northside Corporate Park", priority: "MEDIUM", color: .blue)
                                TaskRow(time: "02:15", ampm: "PM", title: "Site Inspection", location: "Grand Central Station Mall", priority: "LOW", color: .gray)
                            }
                        }
                        
                        Spacer().frame(height: 100) // Space for bottom bar
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                .background(Color.elevateLightGray.opacity(0.3)) // Subtly differentiate scroll background
            }
            
            // Bottom Navbar Floating
            ReusableBottomNav(selectedTab: .constant(.dashboard))
        }
        .navigationBarHidden(true)
    }
}

struct ShortcutBox<Destination: View>: View {
    var title: String
    var icon: String
    var dest: Destination
    
    var body: some View {
        NavigationLink(destination: dest) {
            ShortcutBoxInternal(title: title, icon: icon)
        }
    }
}

struct ShortcutBoxInternal: View {
    var title: String
    var icon: String
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.elevateLightGray)
                    .frame(height: 56)
                Image(systemName: icon)
                    .foregroundColor(.elevateDarkGreen)
                    .font(.system(size: 20))
            }
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.black)
        }
    }
}

struct TaskRow: View {
    var time: String
    var ampm: String
    var title: String
    var location: String
    var priority: String
    var color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 2) {
                Text(time)
                    .font(.system(size: 14, weight: .bold))
                Text(ampm)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.elevateTextGray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                Text(location)
                    .font(.system(size: 12))
                    .foregroundColor(.elevateTextGray)
                
                Text(priority)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.1))
                    .foregroundColor(color)
                    .cornerRadius(8)
            }
            Spacer()
            Image(systemName: "ellipsis")
                .foregroundColor(.elevateTextGray)
                .rotationEffect(.degrees(90))
        }
    }
}

// Ensure these exist if missing in the same file
// struct TabBarButton: View { ... } (Is included previously, keeping to ensure standalone works if not split)
// Actually, I redefined the TabBarButton to make sure it's accessible within TechnicianDashboardView.swift
// Re-adding here so we don't drop it from Overwrite operation.

struct TabBarButton: View {
    var tab: TechnicianDashboardView.TabItem
    var title: String
    var iconName: String
    @Binding var selectedTab: TechnicianDashboardView.TabItem
    
    var isSelected: Bool {
        selectedTab == tab
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        }) {
            if isSelected {
                VStack(spacing: 4) {
                    Image(systemName: iconName)
                        .font(.system(size: 20))
                        .environment(\.symbolVariants, .fill)
                    Text(title)
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.elevateDarkGreen)
                .cornerRadius(30)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: iconName)
                        .font(.system(size: 20))
                    Text(title)
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.elevateTextGray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
    }
}

#Preview {
    TechnicianDashboardView()
}
