import SwiftUI
import Charts

struct ManagerStatisticsView: View {
    @Environment(\.managerTabRouter) private var router
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedTechnician = "All Team"
    let technicians = ["All Team", "Marcus", "Emily", "Alex", "Jordan"]
    
    let weeklyJobs = [
        (week: "WEEK 1", bgValue: 80, fgValue: 50),
        (week: "WEEK 2", bgValue: 60, fgValue: 60),
        (week: "WEEK 3", bgValue: 90, fgValue: 90),
        (week: "WEEK 4", bgValue: 70, fgValue: 65)
    ]
    
    let efficiencyData = [
        (day: 1, val: 50),
        (day: 2, val: 55),
        (day: 3, val: 52),
        (day: 4, val: 68),
        (day: 5, val: 60),
        (day: 6, val: 80)
    ]
    
    var body: some View {
        ZStack {
            Color.elevateLightGray.opacity(0.3).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav(isManager: true, onBack: {
                    router.currentScreen = .dashboard
                    router.selectedTab = .dashboard
                })
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Header with Picker
                        VStack(alignment: .leading, spacing: 16) {
                            Text("CHOOSE A MEMBER")
                                .scaledFont(size: 12, weight: .bold)
                                .foregroundColor(.gray)
                                .tracking(1.5)
                                .padding(.horizontal, 24)
                            
                            Menu {
                                Picker("Technician", selection: $selectedTechnician) {
                                    ForEach(technicians, id: \.self) { tech in
                                        Text(tech).tag(tech)
                                    }
                                }
                            } label: {
                                HStack(spacing: 16) {
                                    ZStack(alignment: .bottomTrailing) {
                                        Circle()
                                            .fill(Color.elevateLightGray)
                                            .frame(width: 64, height: 64)
                                            .overlay(
                                                Image(systemName: selectedTechnician == "All Team" ? "person.3.fill" : "person.fill")
                                                    .font(.system(size: 32))
                                                    .foregroundColor(.elevateDarkGreen)
                                            )
                                        
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 14, height: 14)
                                            .overlay(
                                                Circle().stroke(Color.white, lineWidth: 3)
                                            )
                                            .offset(x: -4, y: -4)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(selectedTechnician)
                                            .scaledFont(size: 22, weight: .bold, design: .rounded)
                                            .foregroundColor(.black)
                                        
                                        Text("ONLINE")
                                            .scaledFont(size: 10, weight: .bold)
                                            .foregroundColor(.elevateDarkGreen)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.elevateDarkGreen.opacity(0.15))
                                            .cornerRadius(12)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.black)
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 24)
                                .background(Color.white)
                                .cornerRadius(24)
                                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
                            }
                            .padding(.horizontal, 24)
                            
                            Text(selectedTechnician == "All Team" ? "Team Performance" : "\(selectedTechnician)'s Performance")
                                .scaledFont(size: 24, weight: .bold, design: .rounded)
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                        }
                        
                        // Top Stats Row
                        HStack(spacing: 16) {
                            StatCard(icon: "star.fill", value: "4.9", title: "AVG. RATING")
                            StatCard(icon: "clock.fill", value: "98%", title: "ON-TIME RATE")
                        }
                        .padding(.horizontal, 24)
                        
                        // Jobs Completed Chart
                        VStack(spacing: 24) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Jobs Completed")
                                        .scaledFont(size: 14, weight: .bold)
                                    Text("Last 30 Days")
                                        .scaledFont(size: 12)
                                        .foregroundColor(.elevateTextGray)
                                }
                                Spacer()
                                Text("124")
                                    .scaledFont(size: 28, weight: .bold)
                                    .foregroundColor(.elevateDarkGreen)
                            }
                            
                            Chart {
                                ForEach(weeklyJobs, id: \.week) { item in
                                    // Background light grey bar
                                    BarMark(
                                        x: .value("Week", item.week),
                                        y: .value("Total", item.bgValue),
                                        width: .ratio(0.8)
                                    )
                                    .foregroundStyle(Color.elevateLightGray)
                                    .cornerRadius(8)
                                    
                                    // Foreground dark green bar
                                    BarMark(
                                        x: .value("Week", item.week),
                                        y: .value("Completed", item.fgValue),
                                        width: .ratio(0.4)
                                    )
                                    .foregroundStyle(Color.elevateDarkGreen)
                                    .cornerRadius(8)
                                }
                            }
                            .frame(height: 140)
                            .chartXAxis {
                                AxisMarks { value in
                                    AxisValueLabel {
                                        if let week = value.as(String.self) {
                                            Text(week)
                                                .scaledFont(size: 10, weight: .bold)
                                                .foregroundColor(.elevateTextGray)
                                        }
                                    }
                                }
                            }
                            .chartYAxis(.hidden)
                        }
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                        .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)
                        
                        // Efficiency Score Chart
                        VStack(spacing: 24) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Efficiency Score")
                                        .scaledFont(size: 14, weight: .bold)
                                    Text(selectedTechnician == "All Team" ? "Vs. Target Average" : "Vs. Team Average")
                                        .scaledFont(size: 12)
                                        .foregroundColor(.elevateTextGray)
                                }
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.right")
                                    Text("12%")
                                }
                                .scaledFont(size: 16, weight: .bold)
                                .foregroundColor(.elevateDarkGreen)
                            }
                            
                            Chart {
                                ForEach(efficiencyData, id: \.day) { item in
                                    LineMark(
                                        x: .value("Day", item.day),
                                        y: .value("Value", item.val)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(Color.elevateDarkGreen)
                                    .lineStyle(StrokeStyle(lineWidth: 3))
                                    
                                    AreaMark(
                                        x: .value("Day", item.day),
                                        y: .value("Value", item.val)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.elevateDarkGreen.opacity(0.1), Color.clear]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                }
                            }
                            .frame(height: 60)
                            .chartXAxis(.hidden)
                            .chartYAxis(.hidden)
                            .chartYScale(domain: 40...90) // To give some headroom matching the image
                        }
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                        .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)
                        
                    }
                }
            }
            
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    ManagerStatisticsView()
}
