import SwiftUI

struct ManagerQuotationApprovalView: View {
    let jobId: String

    @Environment(\.managerTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = ManagerQuotationApprovalViewModel()
    @ObservedObject var settings = AccessibilitySettings.shared

    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                BackHeaderNav(isManager: true, onBack: {
                    router.currentScreen = .jobDetails
                    router.selectedTab = .jobs
                })

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Approve Quotations")
                                .scaledFont(size: 28, weight: .bold, design: .rounded)
                                .foregroundColor(settings.primaryText)
                            Text("Review and approve item requests")
                                .scaledFont(size: 13, weight: .semibold)
                                .foregroundColor(settings.secondaryText)
                        }

                        if viewModel.items.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 40))
                                    .foregroundColor(.elevateTextGray.opacity(0.5))
                                Text("No pending quotations for this job.")
                                    .scaledFont(size: 14)
                                    .foregroundColor(settings.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(viewModel.items) { item in
                                    quotationRow(item)
                                }
                            }

                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("APPROVED COST")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(settings.secondaryText)
                                    Text(currencyString(viewModel.job?.approvedCost))
                                        .scaledFont(size: 18, weight: .bold)
                                        .foregroundColor(settings.accentColor)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(settings.surfaceColor)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                )

                                Button(action: { viewModel.approveAll() }) {
                                    Text("Approve All")
                                        .scaledFont(size: 12, weight: .bold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(settings.isHighContrast ? Color.black : Color.elevateDarkGreen)
                                        .cornerRadius(14)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 2)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                }
            }
        }
        .navigationBarHidden(true)
            .onAppear {
                let actorUserId = appSession.currentUser?.id ?? ""
                viewModel.load(jobId: jobId, actorUserId: actorUserId)
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

    private func quotationRow(_ item: QuotationItem) -> some View {
        let status = item.status.uppercased()
        let isApproved = status == "APPROVED"
        let isRejected = status == "REJECTED"

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .scaledFont(size: 16, weight: .bold)
                        .foregroundColor(settings.primaryText)
                    Text("Qty: \(item.quantity)")
                        .scaledFont(size: 12)
                        .foregroundColor(settings.secondaryText)
                }

                Spacer()

                Text(currencyString(Double(item.quantity) * item.unitPrice))
                    .scaledFont(size: 14, weight: .bold)
                    .foregroundColor(settings.accentColor)
            }

            HStack(spacing: 8) {
                statusPill(status)

                Spacer()

                Button(action: { viewModel.updateStatus(itemId: item.id, status: "APPROVED") }) {
                    Text("Approve")
                        .scaledFont(size: 12, weight: .bold)
                        .foregroundColor(isApproved ? .white : (settings.isHighContrast ? .white : settings.accentColor))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(isApproved ? (settings.isHighContrast ? Color.black : Color.elevateDarkGreen) : settings.surfaceColor)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                        )
                }
                .buttonStyle(.plain)

                Button(action: { viewModel.updateStatus(itemId: item.id, status: "REJECTED") }) {
                    Text("Reject")
                        .scaledFont(size: 12, weight: .bold)
                        .foregroundColor(isRejected ? .white : .red)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(isRejected ? (settings.isHighContrast ? Color.black : Color.red) : (settings.isHighContrast ? Color.black : Color.red.opacity(0.12)))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke((settings.isHighContrast && !isRejected) ? Color.red : (settings.isHighContrast ? Color.white : Color.clear), lineWidth: settings.isHighContrast ? 1 : 0)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(settings.surfaceColor)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }

    private func statusPill(_ status: String) -> some View {
        let normalized = status.uppercased()
        let color: Color
        switch normalized {
        case "APPROVED":
            color = .green
        case "REJECTED":
            color = .red
        default:
            color = .orange
        }

        return Text(normalized)
            .scaledFont(size: 10, weight: .bold)
            .foregroundColor(settings.isHighContrast ? .white : color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(settings.isHighContrast ? Color.black : color.opacity(0.15))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 1)
            )
    }

    private func currencyString(_ value: Double?) -> String {
        guard let value = value else { return "LKR -" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "LKR"
        return formatter.string(from: NSNumber(value: value)) ?? "LKR \(value)"
    }
}

#Preview {
    ManagerQuotationApprovalView(jobId: "sample")
}
