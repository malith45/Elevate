import SwiftUI

struct TechnicianNotificationsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab: TabItem = .dashboard
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = NotificationsViewModel()
    @ObservedObject private var network = NetworkService.shared
    
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
                                .scaledFont(size: 32, weight: .bold, design: .rounded)
                            Spacer()
                            Button("Clear All") {
                                clearNotifications()
                            }
                            .scaledFont(size: 14, weight: .bold)
                            .foregroundColor(.elevateDarkGreen)
                        }
                        .padding(.horizontal, 24)
                        
                        if viewModel.notifications.isEmpty {
                            EmptyStateCard()
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
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Unread Indicator Bar
            Rectangle()
                .fill(item.isRead ? Color.clear : Color.elevateDarkGreen)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(item.title)
                        .scaledFont(size: 16, weight: .bold)
                    Spacer()
                    HStack(spacing: 8) {
                        Text(timeAgo(from: item.createdAt))
                            .scaledFont(size: 10, weight: .bold)
                            .foregroundColor(.elevateTextGray)
                        
                        if !item.isRead {
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
                
                Text(item.body)
                    .scaledFont(size: 14)
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

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundColor(.elevateTextGray)
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

struct EmptyStateCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("No notifications yet")
                .scaledFont(size: 18, weight: .bold)
            Text("Updates about jobs, approvals, and inventory will show up here.")
                .scaledFont(size: 14)
                .foregroundColor(.elevateTextGray)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 24)
    }
}

#Preview {
    TechnicianNotificationsView()
        .environmentObject(AppSession())
}
