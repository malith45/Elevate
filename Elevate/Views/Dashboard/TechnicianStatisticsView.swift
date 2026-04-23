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
            
            // Decorative background elements for "Liquid Glass" effect
            GeometryReader { geo in
                Circle()
                    .fill(settings.accentColor.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: geo.size.width * 0.7, y: -50)
                
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 250, height: 250)
                    .blur(radius: 70)
                    .offset(x: -50, y: geo.size.height * 0.4)
            }
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav(onBack: {
                    dismiss()
                })
                .padding(.bottom, 8)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PERSONAL INSIGHTS")
                                .scaledFont(size: 12, weight: .black)
                                .foregroundColor(settings.secondaryText)
                                .tracking(2)
                            
                            Text("Performance Dashboard")
                                .scaledFont(size: 28, weight: .bold, design: .rounded)
                                .foregroundColor(settings.primaryText)
                        }
                        .padding(.horizontal, 24)
                        
                        // Hero KPI - Completion Rate Gauge
                        VStack(spacing: 20) {
                            HStack {
                                Text("Completion Efficiency")
                                    .scaledFont(size: 16, weight: .bold)
                                Spacer()
                                Text(percentString(viewModel.completionRate))
                                    .scaledFont(size: 24, weight: .heavy, design: .rounded)
                                    .foregroundColor(settings.accentColor)
                            }
                            
                            ZStack {
                                Circle()
                                    .trim(from: 0, to: 0.75)
                                    .stroke(settings.cardStroke, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                    .frame(width: 140, height: 140)
                                    .rotationEffect(.degrees(135))
                                
                                Circle()
                                    .trim(from: 0, to: 0.75 * viewModel.completionRate)
                                    .stroke(
                                        LinearGradient(colors: [settings.accentColor, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                    )
                                    .frame(width: 140, height: 140)
                                    .rotationEffect(.degrees(135))
                                    .animation(.spring(response: 1.0, dampingFraction: 0.7), value: viewModel.completionRate)
                                
                                VStack(spacing: 2) {
                                    Text(percentString(viewModel.completionRate))
                                        .scaledFont(size: 32, weight: .bold, design: .rounded)
                                    Text("COMPLETED")
                                        .scaledFont(size: 10, weight: .black)
                                        .foregroundColor(settings.secondaryText)
                                }
                            }
                            .padding(.vertical, 10)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                        )
                        .padding(.horizontal, 24)
                        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 8)
                        
                        // Summary Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            GlassStatCard(
                                icon: "briefcase.fill",
                                title: "JOBS DONE",
                                value: "\(viewModel.jobs.filter { $0.status.uppercased() == "COMPLETED" }.count)",
                                subtitle: "Total work"
                            )
                            GlassStatCard(
                                icon: "calendar.badge.checkmark",
                                title: "ON SCHEDULE",
                                value: percentString(viewModel.onScheduleRate),
                                subtitle: "Consistency"
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Job Activity Chart
                        VStack(alignment: .leading, spacing: 20) {
                            Text("WORKLOAD TREND")
                                .scaledFont(size: 12, weight: .black)
                                .foregroundColor(settings.secondaryText)
                                .tracking(1.5)
                            
                            Chart {
                                ForEach(viewModel.weeklyStats) { item in
                                    BarMark(
                                        x: .value("Week", item.label),
                                        y: .value("Completed", item.completed),
                                        width: .ratio(0.5)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [settings.accentColor, settings.accentColor.opacity(0.6)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .cornerRadius(6)
                                }
                                
                                RuleMark(y: .value("Average", 5))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                                    .foregroundStyle(settings.secondaryText.opacity(0.5))
                                    .annotation(position: .top, alignment: .trailing) {
                                        Text("Avg")
                                            .scaledFont(size: 10, weight: .bold)
                                            .foregroundColor(settings.secondaryText)
                                    }
                            }
                            .frame(height: 180)
                            .chartXAxis {
                                AxisMarks { value in
                                    AxisValueLabel {
                                        if let label = value.as(String.self) {
                                            Text(label)
                                                .scaledFont(size: 10, weight: .bold)
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
                        
                        // Priority Distribution
                        VStack(alignment: .leading, spacing: 20) {
                            Text("TASK DISTRIBUTION")
                                .scaledFont(size: 12, weight: .black)
                                .foregroundColor(settings.secondaryText)
                                .tracking(1.5)
                            
                            Chart(viewModel.jobsByPriority) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 2
                                )
                                .cornerRadius(4)
                                .foregroundStyle(by: .value("Priority", item.priority))
                            }
                            .frame(height: 200)
                            .chartLegend(position: .bottom, spacing: 16)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                        )
                        .padding(.horizontal, 24)
                        
                        // Bottom Padding
                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
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
}

struct GlassStatCard: View {
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
                .background(settings.accentColor.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .scaledFont(size: 24, weight: .bold, design: .rounded)
                    .foregroundColor(settings.primaryText)
                
                Text(title)
                    .scaledFont(size: 10, weight: .black)
                    .foregroundColor(settings.secondaryText)
            }
            
            Text(subtitle)
                .scaledFont(size: 11)
                .foregroundColor(settings.secondaryText.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
    }
}

#Preview {
    TechnicianStatisticsView()
        .environmentObject(AppSession())
}
