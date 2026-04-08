import SwiftUI

struct ManagerQuotationApprovalView: View {
    let jobId: String

    @Environment(\.managerTabRouter) private var router
    @StateObject private var viewModel = ManagerQuotationApprovalViewModel()

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                BackHeaderNav(isManager: true, onBack: {
                    router.currentScreen = .jobDetails
                    router.selectedTab = .jobs
                })

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Approve Quotations")
                            .scaledFont(size: 28, weight: .bold, design: .rounded)
                            .foregroundColor(.elevateDarkGreen)

                        if viewModel.items.isEmpty {
                            EmptyStateCard()
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
                                        .foregroundColor(.elevateTextGray)
                                    Text(currencyString(viewModel.job?.approvedCost))
                                        .scaledFont(size: 18, weight: .bold)
                                        .foregroundColor(.elevateDarkGreen)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color.elevateLightGray)
                                .cornerRadius(12)

                                Button(action: { viewModel.approveAll() }) {
                                    Text("Approve All")
                                        .scaledFont(size: 12, weight: .bold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.elevateDarkGreen)
                                        .cornerRadius(12)
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
        .onAppear { viewModel.load(jobId: jobId) }
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

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .scaledFont(size: 16, weight: .bold)
                    Text("Qty: \(item.quantity)")
                        .scaledFont(size: 12)
                        .foregroundColor(.elevateTextGray)
                }

                Spacer()

                Text(currencyString(Double(item.quantity) * item.unitPrice))
                    .scaledFont(size: 14, weight: .bold)
                    .foregroundColor(.elevateDarkGreen)
            }

            HStack(spacing: 8) {
                statusPill(status)

                Spacer()

                Button(action: { viewModel.updateStatus(itemId: item.id, status: "APPROVED") }) {
                    Text("Approve")
                        .scaledFont(size: 12, weight: .bold)
                        .foregroundColor(isApproved ? .white : .elevateDarkGreen)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(isApproved ? Color.elevateDarkGreen : Color.elevateLightGray)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)

                Button(action: { viewModel.updateStatus(itemId: item.id, status: "REJECTED") }) {
                    Text("Reject")
                        .scaledFont(size: 12, weight: .bold)
                        .foregroundColor(isRejected ? .white : .red)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(isRejected ? Color.red : Color.red.opacity(0.12))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)
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
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .cornerRadius(10)
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
