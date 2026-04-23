import SwiftUI
import Charts

struct ManagerStatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = StatisticsViewModel()
    @ObservedObject private var network = NetworkService.shared
    @ObservedObject var settings = AccessibilitySettings.shared
    @State private var selectedTechnicianId: String?
    
    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()
            
            // Decorative background elements
            GeometryReader { geo in
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 350, height: 350)
                    .blur(radius: 90)
                    .offset(x: geo.size.width * 0.6, y: geo.size.height * 0.1)
                
                Circle()
                    .fill(settings.accentColor.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: -50, y: geo.size.height * 0.6)
            }
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav(isManager: true, onBack: {
                    dismiss()
                })
                .padding(.bottom, 8)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        
                        // Header with Selector
                        VStack(alignment: .leading, spacing: 16) {
                            Text("ORGANIZATIONAL INTEL")
                                .scaledFont(size: 12, weight: .black)
                                .foregroundColor(settings.secondaryText)
                                .tracking(2)
                            
                            Menu {
                                Button(action: { selectedTechnicianId = nil }) {
                                    Label("All Organization", systemImage: "building.2.fill")
                                }
                                
                                Divider()
                                
                                ForEach(viewModel.technicians, id: \.id) { tech in
                                    Button(action: { selectedTechnicianId = tech.id }) {
                                        Label(displayName(for: tech), systemImage: "person.fill")
                                    }
                                }
                            } label: {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(settings.accentColor.opacity(0.1))
                                            .frame(width: 52, height: 52)
                                        
                                        Image(systemName: selectedTechnicianId == nil ? "building.2.fill" : "person.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(settings.accentColor)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(selectedTechnicianLabel())
                                            .scaledFont(size: 20, weight: .bold, design: .rounded)
                                            .foregroundColor(settings.primaryText)
                                        Text(selectedTechnicianId == nil ? "Full Workforce" : "Technician Insights")
                                            .scaledFont(size: 12)
                                            .foregroundColor(settings.secondaryText)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.up.down")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(settings.secondaryText)
                                }
                                .padding(16)
                                .background(.ultraThinMaterial)
                                .cornerRadius(24)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Top Level KPIs
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            GlassStatCard(
                                icon: "person.2.fill",
                                title: "TEAM SIZE",
                                value: "\(viewModel.technicians.count)",
                                subtitle: "Active staff"
                            )
                            GlassStatCard(
                                icon: "target",
                                title: "AVG EFFICIENCY",
                                value: percentString(viewModel.completionRate),
                                subtitle: "Organization"
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Performance Breakdown Chart
                        VStack(alignment: .leading, spacing: 20) {
                            Text(selectedTechnicianId == nil ? "TEAM COMPLETIONS" : "ACTIVITY TREND")
                                .scaledFont(size: 12, weight: .black)
                                .foregroundColor(settings.secondaryText)
                                .tracking(1.5)
                            
                            Chart {
                                ForEach(viewModel.weeklyStats) { item in
                                    AreaMark(
                                        x: .value("Week", item.label),
                                        y: .value("Completed", item.completed)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [settings.accentColor.opacity(0.3), settings.accentColor.opacity(0)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    
                                    LineMark(
                                        x: .value("Week", item.label),
                                        y: .value("Completed", item.completed)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(settings.accentColor)
                                    .lineStyle(StrokeStyle(lineWidth: 3))
                                }
                            }
                            .frame(height: 180)
                            .chartXAxis {
                                AxisMarks { value in
                                    AxisValueLabel {
                                        if let label = value.as(String.self) {
                                            Text(label).scaledFont(size: 10, weight: .bold)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                        )
                        .padding(.horizontal, 24)
                        
                        // Technician Leaderboard (Only if no tech selected)
                        if selectedTechnicianId == nil {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("WORKFORCE EFFICIENCY")
                                    .scaledFont(size: 12, weight: .black)
                                    .foregroundColor(settings.secondaryText)
                                    .tracking(1.5)
                                
                                VStack(spacing: 16) {
                                    ForEach(viewModel.technicians.prefix(5), id: \.id) { tech in
                                        HStack(spacing: 12) {
                                            Text(displayName(for: tech).prefix(1))
                                                .scaledFont(size: 14, weight: .bold)
                                                .frame(width: 32, height: 32)
                                                .background(settings.accentColor.opacity(0.2))
                                                .clipShape(Circle())
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(displayName(for: tech))
                                                    .scaledFont(size: 14, weight: .bold)
                                                Text("Senior Technician")
                                                    .scaledFont(size: 10)
                                                    .foregroundColor(settings.secondaryText)
                                            }
                                            
                                            Spacer()
                                            
                                            Text("Top Performer")
                                                .scaledFont(size: 10, weight: .bold)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.green.opacity(0.1))
                                                .foregroundColor(.green)
                                                .cornerRadius(8)
                                        }
                                        if tech.id != viewModel.technicians.prefix(5).last?.id {
                                            Divider().background(settings.cardStroke)
                                        }
                                    }
                                }
                            }
                            .padding(24)
                            .background(.ultraThinMaterial)
                            .cornerRadius(32)
                            .overlay(
                                RoundedRectangle(cornerRadius: 32)
                                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                            )
                            .padding(.horizontal, 24)
                        } else {
                            // Status Distribution for individual
                            VStack(alignment: .leading, spacing: 20) {
                                Text("JOB STATUS SPREAD")
                                    .scaledFont(size: 12, weight: .black)
                                    .foregroundColor(settings.secondaryText)
                                    .tracking(1.5)
                                
                                Chart(viewModel.jobsByStatus) { item in
                                    BarMark(
                                        x: .value("Count", item.count),
                                        y: .value("Status", item.status)
                                    )
                                    .foregroundStyle(by: .value("Status", item.status))
                                    .cornerRadius(6)
                                }
                                .frame(height: 150)
                                .chartLegend(.hidden)
                            }
                            .padding(24)
                            .background(.ultraThinMaterial)
                            .cornerRadius(32)
                            .overlay(
                                RoundedRectangle(cornerRadius: 32)
                                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                            )
                            .padding(.horizontal, 24)
                        }
                        
                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { loadStats() }
        .onChange(of: selectedTechnicianId) { _, _ in loadStats() }
    }
    
    private func loadStats() {
        guard let user = appSession.currentUser else { return }
        viewModel.load(
            organizationId: user.organizationId,
            userId: user.id,
            role: user.role,
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
        else { return "Organization Overview" }
        return displayName(for: tech)
    }

    private func percentString(_ value: Double) -> String {
        let percent = Int((value * 100).rounded())
        return "\(percent)%"
    }
}

#Preview {
    ManagerStatisticsView()
        .environmentObject(AppSession())
}
