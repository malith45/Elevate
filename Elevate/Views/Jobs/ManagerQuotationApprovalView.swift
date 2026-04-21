import SwiftUI

struct ManagerQuotationApprovalView: View {
    let jobId: String?

    @Environment(\.managerTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = ManagerQuotationApprovalViewModel()
    @ObservedObject var settings = AccessibilitySettings.shared
    private let localStorage = LocalStorageService.shared

    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                BackHeaderNav(isManager: true, onBack: {
                    if let _ = jobId {
                        router.currentScreen = .jobDetails
                    } else {
                        router.currentScreen = .pendingQuotations
                    }
                    router.selectedTab = .jobs
                })

                VStack(alignment: .leading, spacing: 24) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Approve Items")
                            .scaledFont(size: 28, weight: .bold, design: .rounded)
                            .foregroundColor(settings.primaryText)
                        Text("Review and dispatch equipment approvals")
                            .scaledFont(size: 15, weight: .medium)
                            .foregroundColor(settings.secondaryText)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        if viewModel.items.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundColor(settings.secondaryText.opacity(0.3))
                                Text("No pending quotations for this job.")
                                    .scaledFont(size: 15, weight: .medium)
                                    .foregroundColor(settings.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 80)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(viewModel.items) { item in
                                    quotationRow(item, jobId: jobId)
                                }
                            }
                        }

                        if !viewModel.items.isEmpty {
                            bottomApprovalBar
                                .padding(.top, 16)
                                .padding(.bottom, 32) // Gentle breathing room at the end
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            let actorUserId = appSession.currentUser?.id ?? ""
            let organizationId = appSession.currentUser?.organizationId ?? ""
            viewModel.load(jobId: jobId, organizationId: organizationId, actorUserId: actorUserId)
        }
        .alert("Quotation", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }



    private var bottomApprovalBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ESTIMATED COST")
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundColor(settings.secondaryText)
                    .tracking(0.5)
                Text(currencyString(viewModel.job?.approvedCost))
                    .scaledFont(size: 20, weight: .bold)
                    .foregroundColor(settings.accentColor)
            }
            
            Spacer()
            
            Button(action: { 
                HapticManager.shared.playImpact(style: .medium)
                viewModel.approveAll(jobId: viewModel.job?.id) 
            }) {
                HStack {
                    Text("APPROVE ALL")
                    Image(systemName: "checkmark.shield.fill")
                }
                .scaledFont(size: 13, weight: .bold)
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .padding(.horizontal, 24)
                .background(settings.isHighContrast ? Color.black : Color.elevateDarkGreen)
                .cornerRadius(12)
                .shadow(color: Color.elevateDarkGreen.opacity(0.15), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 2)
                )
            }
        }
        .padding(24)
        .background(settings.surfaceColor)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }



    private func quotationRow(_ item: QuotationItem, jobId: String?) -> some View {
        let status = item.status.uppercased()
        let isApproved = status == "APPROVED"
        let isRejected = status == "REJECTED"

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .scaledFont(size: 15, weight: .bold)
                        .foregroundColor(settings.primaryText)
                    Text("Quantity: \(item.quantity)")
                        .scaledFont(size: 12, weight: .medium)
                        .foregroundColor(settings.secondaryText)
                }

                Spacer()

                Text(currencyString(Double(item.quantity) * item.unitPrice))
                    .scaledFont(size: 15, weight: .bold)
                    .foregroundColor(settings.accentColor)
            }

            HStack(spacing: 12) {
                statusPill(status)

                Spacer()

                HStack(spacing: 8) {
                    Button(action: {
                        if let jobId = jobId {
                            HapticManager.shared.playImpact(style: .rigid)
                            viewModel.updateStatus(jobId: jobId, itemId: item.id, status: "APPROVED")
                        }
                    }) {
                        Image(systemName: isApproved ? "checkmark.circle.fill" : "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isApproved ? .white : .green)
                            .padding(10)
                            .background(isApproved ? (settings.isHighContrast ? Color.black : Color.green) : Color.green.opacity(0.1))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.green.opacity(0.2), lineWidth: 1))
                    }

                    Button(action: {
                        if let jobId = jobId {
                            HapticManager.shared.playImpact(style: .rigid)
                            viewModel.updateStatus(jobId: jobId, itemId: item.id, status: "REJECTED")
                        }
                    }) {
                        Image(systemName: isRejected ? "xmark.circle.fill" : "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isRejected ? .white : .red)
                            .padding(10)
                            .background(isRejected ? (settings.isHighContrast ? Color.black : Color.red) : Color.red.opacity(0.1))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.red.opacity(0.2), lineWidth: 1))
                    }
                }
            }
        }
        .padding(16)
        .background(settings.isHighContrast ? Color.black : settings.surfaceColor.opacity(0.6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
    }

    private func statusPill(_ status: String) -> some View {
        let normalized = status.uppercased()
        let color: Color
        switch normalized {
        case "APPROVED": color = .green
        case "REJECTED": color = .red
        default: color = .orange
        }

        return Text(normalized)
            .scaledFont(size: 9, weight: .black)
            .foregroundColor(settings.isHighContrast ? .white : color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(settings.isHighContrast ? Color.black : color.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 1)
            )
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
        let user = localStorage.fetchUser(id: userId)
        if let user = user {
            return user.displayName.isEmpty ? user.username : user.displayName
        }
        return "Technician"
    }
}

#Preview {
    ManagerQuotationApprovalView(jobId: "sample")
}
