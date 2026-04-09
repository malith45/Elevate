import SwiftUI
import Charts

struct ManagerStatisticsView: View {
    @Environment(\.managerTabRouter) private var router
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = StatisticsViewModel()
    @ObservedObject private var network = NetworkService.shared
    @State private var selectedTechnicianId: String?
    
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
                                Picker("Technician", selection: $selectedTechnicianId) {
                                    Text("All Team").tag(Optional<String>(nil))
                                    ForEach(viewModel.technicians, id: \.id) { tech in
                                        Text(displayName(for: tech)).tag(Optional(tech.id))
                                    }
                                }
                            } label: {
                                HStack(spacing: 16) {
                                    ZStack(alignment: .bottomTrailing) {
                                        Circle()
                                            .fill(Color.elevateLightGray)
                                            .frame(width: 64, height: 64)
                                            .overlay(
                                                Image(systemName: selectedTechnicianId == nil ? "person.3.fill" : "person.fill")
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
                                        Text(selectedTechnicianLabel())
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
                            
                            Text(selectedTechnicianId == nil ? "Team Performance" : "\(selectedTechnicianLabel())'s Performance")
                                .scaledFont(size: 24, weight: .bold, design: .rounded)
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                        }
                        
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
                                Text("\(viewModel.weeklyStats.reduce(0) { $0 + $1.completed })")
                                    .scaledFont(size: 28, weight: .bold)
                                    .foregroundColor(.elevateDarkGreen)
                            }
                            
                            Chart {
                                ForEach(viewModel.weeklyStats) { item in
                                    // Background light grey bar
                                    BarMark(
                                        x: .value("Week", item.label),
                                        y: .value("Total", item.total),
                                        width: .ratio(0.8)
                                    )
                                    .foregroundStyle(Color.elevateLightGray)
                                    .cornerRadius(8)
                                    
                                    // Foreground dark green bar
                                    BarMark(
                                        x: .value("Week", item.label),
                                        y: .value("Completed", item.completed),
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
                                    Text(selectedTechnicianId == nil ? "Vs. Target Average" : "Vs. Team Average")
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
                                ForEach(viewModel.efficiencyStats) { item in
                                    LineMark(
                                        x: .value("Day", item.dayIndex),
                                        y: .value("Value", item.value)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(Color.elevateDarkGreen)
                                    .lineStyle(StrokeStyle(lineWidth: 3))
                                    
                                    AreaMark(
                                        x: .value("Day", item.dayIndex),
                                        y: .value("Value", item.value)
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
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 96)
                }
            }
            
        }
        .navigationBarHidden(true)
        .onAppear {
            loadStats()
        }
        .onChange(of: selectedTechnicianId) { _, _ in
            loadStats()
        }
        .onChange(of: network.isOnline) { _, _ in
            loadStats()
        }
    }

    private func loadStats() {
        guard let user = appSession.currentUser else { return }
        viewModel.load(
            organizationId: user.organizationId,
            userId: user.id,
            isOnline: network.isOnline,
            technicianId: selectedTechnicianId
        )
    }

    private func displayName(for user: User) -> String {
        user.displayName.isEmpty ? user.username : user.displayName
    }

    private func selectedTechnicianLabel() -> String {
        guard let selectedId = selectedTechnicianId,
              let tech = viewModel.technicians.first(where: { $0.id == selectedId })
        else { return "All Team" }
        return displayName(for: tech)
    }

    private func percentString(_ value: Double) -> String {
        let percent = Int((value * 100).rounded())
        return "\(percent)%"
    }

    private func ratingString() -> String {
        let rating = max(3.0, min(5.0, 5.0 * viewModel.completionRate))
        return String(format: "%.1f", rating)
    }
}

#Preview {
    ManagerStatisticsView()
}
