import SwiftUI
import Charts

struct TechnicianStatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = StatisticsViewModel()
    @ObservedObject private var network = NetworkService.shared
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav(onBack: {
                    dismiss()
                })
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PERFORMANCE ANALYTICS")
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(settings.secondaryText)
                            
                            Text("Your Performance")
                                .scaledFont(size: 28, weight: .medium, design: .rounded)
                                .foregroundColor(settings.primaryText)
                        }
                        .padding(.horizontal, 24)
                        
                        // Jobs Completed Chart
                        VStack(spacing: 24) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Jobs Completed")
                                        .scaledFont(size: 14, weight: .bold)
                                        .foregroundColor(settings.primaryText)
                                    Text("Last 30 Days")
                                        .scaledFont(size: 12)
                                        .foregroundColor(settings.secondaryText)
                                }
                                Spacer()
                                Text("\(viewModel.weeklyStats.reduce(0) { $0 + $1.completed })")
                                    .scaledFont(size: 28, weight: .bold)
                                    .foregroundColor(settings.accentColor)
                            }
                            
                            Chart {
                                ForEach(viewModel.weeklyStats) { item in
                                    // Background light grey bar
                                    BarMark(
                                        x: .value("Week", item.label),
                                        y: .value("Total", item.total),
                                        width: .ratio(0.8)
                                    )
                                    .foregroundStyle(settings.isHighContrast ? settings.secondaryText.opacity(0.3) : Color.elevateLightGray)
                                    .cornerRadius(8)
                                    
                                    // Foreground dark green bar
                                    BarMark(
                                        x: .value("Week", item.label),
                                        y: .value("Completed", item.completed),
                                        width: .ratio(0.4)
                                    )
                                    .foregroundStyle(settings.accentColor)
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
                                                .foregroundColor(settings.secondaryText)
                                        }
                                    }
                                }
                            }
                            .chartYAxis(.hidden)
                        }
                        .padding(24)
                        .background(settings.surfaceColor)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                        )
                        .padding(.horizontal, 24)
                        .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)
                        
                        // Efficiency Score Chart
                        VStack(spacing: 24) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Efficiency Score")
                                        .scaledFont(size: 14, weight: .bold)
                                    Text(viewModel.comparisonLabel)
                                        .scaledFont(size: 12)
                                        .foregroundColor(settings.secondaryText)
                                }
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: viewModel.comparisonIsPositive ? "arrow.up.right" : "arrow.down.right")
                                    Text(comparisonPercentString())
                                }
                                .scaledFont(size: 16, weight: .bold)
                                .foregroundColor(settings.isHighContrast ? settings.primaryText : (viewModel.comparisonIsPositive ? settings.accentColor : .red))
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
                        .background(settings.surfaceColor)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                        )
                        .padding(.horizontal, 24)
                        .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)
                        
                    }
                }
            }
            
        }
        .navigationBarHidden(true)
        .onAppear {
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
            role: user.role,
            isOnline: network.isOnline,
            technicianId: user.id
        )
    }

    private func percentString(_ value: Double) -> String {
        let percent = Int((value * 100).rounded())
        return "\(percent)%"
    }

    private func ratingString() -> String {
        let rating = max(3.0, min(5.0, 5.0 * viewModel.completionRate))
        return String(format: "%.1f", rating)
    }

    private func comparisonPercentString() -> String {
        let delta = abs(viewModel.comparisonDelta)
        let percent = Int((delta * 100).rounded())
        return "\(percent)%"
    }
}

struct StatCard: View {
    var icon: String
    var value: String
    var title: String
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(settings.accentColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .scaledFont(size: 24, weight: .regular)
                    .foregroundColor(settings.primaryText)
                Text(title)
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundColor(settings.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(settings.surfaceColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    TechnicianStatisticsView()
}
