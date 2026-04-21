import SwiftUI

struct ManagerPendingQuotationListView: View {
    @Environment(\.managerTabRouter) private var router
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = ManagerQuotationApprovalViewModel()
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                BackHeaderNav(isManager: true, onBack: {
                    dismiss()
                })
                
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pending Approvals")
                            .scaledFont(size: 28, weight: .bold, design: .rounded)
                            .foregroundColor(settings.primaryText)
                        Text("Equipment and service requests requiring your review")
                            .scaledFont(size: 15, weight: .medium)
                            .foregroundColor(settings.secondaryText)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            if viewModel.jobs.isEmpty {
                                emptyState
                            } else {
                                ForEach(viewModel.jobs) { job in
                                    PendingQuotationJobCard(job: job) {
                                        router.selectedJobId = job.id
                                        router.path.append(ManagerScreen.quotationApproval)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        let actorUserId = appSession.currentUser?.id ?? ""
        let organizationId = appSession.currentUser?.organizationId ?? ""
        viewModel.load(jobId: nil, organizationId: organizationId, actorUserId: actorUserId)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(settings.surfaceColor)
                    .frame(width: 80, height: 80)
                    .overlay(Circle().stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth))
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 32))
                    .foregroundColor(settings.primaryText)
            }
            .padding(.top, 60)
            
            VStack(spacing: 8) {
                Text("All Caught Up")
                    .scaledFont(size: 18, weight: .bold)
                    .foregroundColor(settings.primaryText)
                Text("No pending quotations require your attention right now.")
                    .scaledFont(size: 14)
                    .foregroundColor(settings.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PendingQuotationJobCard: View {
    let job: Job
    let action: () -> Void
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        Button(action: {
            HapticManager.shared.playImpact(style: .medium)
            action()
        }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(job.title)
                            .scaledFont(size: 17, weight: .bold)
                            .foregroundColor(settings.primaryText)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 10))
                            Text(displayName(for: job.assignedUserId).uppercased())
                                .scaledFont(size: 10, weight: .bold)
                        }
                        .foregroundColor(settings.secondaryText)
                    }
                    
                    Spacer()
                    
                    let pendingCount = job.quotationItems.filter { $0.status.uppercased() == "PENDING" }.count
                    Text("\(pendingCount) PENDING")
                        .scaledFont(size: 9, weight: .black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(settings.isHighContrast ? settings.surfaceColor : Color.orange.opacity(0.12))
                        .foregroundColor(settings.isHighContrast ? settings.primaryText : .orange)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                        )
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ESTIMATED VALUE")
                            .scaledFont(size: 10, weight: .bold)
                            .foregroundColor(settings.secondaryText)
                        Text(currencyString(job.approvedCost))
                            .scaledFont(size: 15, weight: .bold)
                            .foregroundColor(settings.accentColor)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("Review Items")
                            .scaledFont(size: 12, weight: .bold)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(settings.accentColor)
                }
            }
            .padding(20)
            .background(settings.surfaceColor)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
    
    private func currencyString(_ value: Double?) -> String {
        guard let value = value else { return "LKR 0.00" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "LKR"
        formatter.locale = Locale(identifier: "en_LK")
        return formatter.string(from: NSNumber(value: value)) ?? "LKR \(String(format: "%.2f", value))"
    }
    
    private func displayName(for userId: String) -> String {
        let user = LocalStorageService.shared.fetchUser(id: userId)
        if let user = user {
            return user.displayName.isEmpty ? user.username : user.displayName
        }
        return "Technician"
    }
}
