import SwiftUI

struct TechnicianNotificationsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab: TabItem = .dashboard
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = NotificationsViewModel()
    @ObservedObject private var network = NetworkService.shared
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Header
                        HStack {
                            Text("Notifications")
                                .scaledFont(size: 32, weight: .bold, design: .rounded)
                                .foregroundColor(settings.primaryText)
                            Spacer()
                            Button("Clear All") {
                                clearNotifications()
                            }
                            .scaledFont(size: 14, weight: .bold)
                            .foregroundColor(settings.accentColor)
                        }
                        .padding(.horizontal, 24)
                        
                        if viewModel.notifications.isEmpty {
                            EmptyStateView(title: "No notifications yet", message: "Updates about jobs, approvals, and inventory will show up here.")
                        } else {
                            NotificationSection(title: "TODAY", items: viewModel.todayItems, onTap: handleTap, destinationProvider: notificationDestination)
                            NotificationSection(title: "YESTERDAY", items: viewModel.yesterdayItems, onTap: handleTap, destinationProvider: notificationDestination)
                            NotificationSection(title: "EARLIER", items: viewModel.olderItems, onTap: handleTap, destinationProvider: notificationDestination)
                        }
                        
                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 16)
                }
            }
            
        }
        .navigationBarHidden(true)
        .onAppear {
            loadNotifications()
        }
        .onChange(of: network.isOnline) { _, _ in
            loadNotifications()
        }
        .onReceive(NotificationCenter.default.publisher(for: .notificationsDidChange)) { _ in
            loadNotifications()
        }
    }

    private func loadNotifications() {
        guard let user = appSession.currentUser else { return }
        let isOnline = NetworkService.shared.isOnline
        viewModel.load(organizationId: user.organizationId, userId: user.id, isOnline: isOnline)
    }

    private func clearNotifications() {
        guard let user = appSession.currentUser else { return }
        viewModel.clearAll(organizationId: user.organizationId, userId: user.id)
    }

    private func handleTap(_ item: NotificationItem) {
        viewModel.markRead(item, isOnline: NetworkService.shared.isOnline)
    }
}

struct NotificationCard: View {
    var item: NotificationItem
    var onTap: (() -> Void)?
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Unread Indicator Bar
            Rectangle()
                .fill(item.isRead ? Color.clear : settings.accentColor)
                .frame(width: 4)
                .cornerRadius(2)
                .overlay(
                    Rectangle()
                        .stroke(settings.isHighContrast && !item.isRead ? Color.white : Color.clear, lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(item.title)
                        .scaledFont(size: 16, weight: .bold)
                        .foregroundColor(settings.primaryText)
                    Spacer()
                    HStack(spacing: 8) {
                        Text(timeAgo(from: item.createdAt))
                            .scaledFont(size: 10, weight: .bold)
                            .foregroundColor(settings.secondaryText)
                        
                        if !item.isRead {
                            Circle()
                                .fill(settings.accentColor)
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle().stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 1)
                                )
                        } else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 8, height: 8) // spacing preservation
                        }
                    }
                }
                
                Text(item.body)
                    .scaledFont(size: 14)
                    .foregroundColor(settings.isHighContrast ? settings.primaryText : Color.gray)
                    .lineSpacing(4)
            }
            .padding(.vertical, 16)
            .padding(.trailing, 16)
        }
        .background(settings.surfaceColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 24)
        .onTapGesture {
            onTap?()
        }
    }

    private func timeAgo(from date: Date) -> String {
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        if minutes < 60 {
            return "\(max(minutes, 1))M AGO"
        }
        let hours = minutes / 60
        if hours < 24 {
            return "\(hours)H AGO"
        }
        let days = hours / 24
        return "\(days)D AGO"
    }
}

struct NotificationSection: View {
    let title: String
    let items: [NotificationItem]
    var onTap: ((NotificationItem) -> Void)?
    var destinationProvider: ((NotificationItem) -> AnyView?)? = nil
    @ObservedObject var settings = AccessibilitySettings.shared

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundColor(settings.secondaryText)
                    .padding(.horizontal, 24)

                ForEach(items) { item in
                    if let destination = destinationProvider?(item) {
                        NavigationLink(destination: destination) {
                            NotificationCard(item: item, onTap: {
                                onTap?(item)
                            })
                        }
                        .buttonStyle(.plain)
                    } else {
                        NotificationCard(item: item, onTap: {
                            onTap?(item)
                        })
                    }
                }
            }
        }
    }
}

private func notificationDestination(for item: NotificationItem) -> AnyView? {
    guard let targetId = item.targetId else { return nil }
    let type = item.type.uppercased()
    if type.contains("ISSUE") {
        return AnyView(JobIssueReportView(jobId: targetId))
    }
    if type.contains("QUOTATION") || type.contains("QUOTE") {
        return AnyView(QuotationStatusView(jobId: targetId))
    }
    if type.contains("JOB") {
        return AnyView(JobDetailsView(jobId: targetId))
    }
    return nil
}

#Preview {
    TechnicianNotificationsView()
        .environmentObject(AppSession())
}
