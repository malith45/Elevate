import SwiftUI

struct QuotationStatusView: View {
    let jobId: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.technicianTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = QuotationStatusViewModel()
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
                    VStack(alignment: .leading, spacing: 32) {
                        // Header Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quotation Status")
                                .scaledFont(size: 28, weight: .bold, design: .rounded)
                                .foregroundColor(settings.primaryText)
                            Text("Track approved and pending service items")
                                .scaledFont(size: 15, weight: .medium)
                                .foregroundColor(settings.secondaryText)
                        }
                        .padding(.top, 20)
                        
                        // Approved Items Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("APPROVED")
                                    .scaledFont(size: 12, weight: .bold)
                                    .foregroundColor(settings.secondaryText)
                                    .tracking(1)
                                Spacer()
                                Text("\(viewModel.approvedItems.count) ITEMS")
                                    .scaledFont(size: 10, weight: .bold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(settings.isHighContrast ? Color.black : Color.green.opacity(0.12))
                                    .foregroundColor(settings.isHighContrast ? .white : .green)
                                    .cornerRadius(8)
                            }

                            if viewModel.approvedItems.isEmpty {
                                emptyStatePlaceholder(message: "No approved items yet")
                            } else {
                                ForEach(viewModel.approvedItems, id: \.id) { item in
                                    QuotationItemCard(
                                        title: item.name,
                                        quantityText: "Qty: \(item.quantity)",
                                        priceText: currencyString(Double(item.quantity) * item.unitPrice),
                                        statusText: nil,
                                        isApproved: true,
                                        removeAction: nil
                                    )
                                }
                            }
                        }
                        
                        // Pending Items Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("PENDING APPROVAL")
                                    .scaledFont(size: 12, weight: .bold)
                                    .foregroundColor(settings.secondaryText)
                                    .tracking(1)
                                Spacer()
                                Text("\(viewModel.pendingItems.count) ITEMS")
                                    .scaledFont(size: 10, weight: .bold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(settings.isHighContrast ? Color.black : Color.orange.opacity(0.12))
                                    .foregroundColor(settings.isHighContrast ? .white : .orange)
                                    .cornerRadius(8)
                            }

                            if viewModel.pendingItems.isEmpty {
                                emptyStatePlaceholder(message: "No pending items")
                            } else {
                                ForEach(viewModel.pendingItems, id: \.id) { item in
                                    QuotationItemCard(
                                        title: item.name,
                                        quantityText: "Qty: \(item.quantity)",
                                        priceText: currencyString(Double(item.quantity) * item.unitPrice),
                                        statusText: nil,
                                        isApproved: false,
                                        removeAction: {
                                            guard let user = appSession.currentUser else { return }
                                            viewModel.removePendingItem(
                                                jobId: jobId,
                                                itemId: item.id,
                                                userId: user.id,
                                                organizationId: user.organizationId
                                            )
                                        }
                                    )
                                }
                            }
                        }

                        // Rejected Items Section
                        if !viewModel.rejectedItems.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("REJECTED")
                                        .scaledFont(size: 12, weight: .bold)
                                        .foregroundColor(settings.secondaryText)
                                        .tracking(1)
                                    Spacer()
                                    Text("\(viewModel.rejectedItems.count) ITEMS")
                                        .scaledFont(size: 10, weight: .bold)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(settings.isHighContrast ? Color.black : Color.red.opacity(0.12))
                                        .foregroundColor(settings.isHighContrast ? .white : .red)
                                        .cornerRadius(8)
                                }

                                ForEach(viewModel.rejectedItems, id: \.id) { item in
                                    QuotationItemCard(
                                        title: item.name,
                                        quantityText: "Qty: \(item.quantity)",
                                        priceText: currencyString(Double(item.quantity) * item.unitPrice),
                                        statusText: nil,
                                        isApproved: false,
                                        removeAction: nil
                                    )
                                }
                            }
                        }
                        
                        // Summary Section
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("TOTAL VALUE")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(.white.opacity(0.8))
                                        .tracking(0.5)
                                    Text("LKR")
                                        .scaledFont(size: 12, weight: .semibold)
                                        .foregroundColor(.white.opacity(0.9))
                                    Text("\(formattedTotal())")
                                        .scaledFont(size: 24, weight: .bold)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .padding(20)
                                .background(settings.isHighContrast ? Color.black : Color.elevateDarkGreen)
                                .cornerRadius(16)
                                .shadow(color: Color.elevateDarkGreen.opacity(0.2), radius: 10, x: 0, y: 5)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("TOTAL ITEMS")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(settings.secondaryText)
                                        .tracking(0.5)
                                    Text("COUNT")
                                        .scaledFont(size: 12, weight: .semibold)
                                        .foregroundColor(settings.secondaryText.opacity(0.7))
                                    Text("\(viewModel.approvedItems.count)")
                                        .scaledFont(size: 24, weight: .bold)
                                        .foregroundColor(settings.accentColor)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .padding(20)
                                .background(settings.surfaceColor)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                )
                                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
                            }
                            .fixedSize(horizontal: false, vertical: true)
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    HapticManager.shared.playImpact(style: .light)
                                    router.path = NavigationPath([TechnicianScreen.jobDetails])
                                }) {
                                    Text("GO BACK")
                                        .scaledFont(size: 14, weight: .bold)
                                        .foregroundColor(settings.secondaryText)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(settings.surfaceColor)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(settings.cardStroke, lineWidth: 1)
                                        )
                                }

                                Button(action: {
                                    router.selectedJobId = jobId
                                    router.path.append(TechnicianScreen.inventory)
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("ADD ITEMS")
                                    }
                                    .scaledFont(size: 14, weight: .bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(settings.isHighContrast ? Color.black : Color.elevateDarkGreen)
                                    .cornerRadius(12)
                                    .shadow(color: Color.elevateDarkGreen.opacity(0.2), radius: 8, x: 0, y: 4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 8)
                        
                        Spacer().frame(height: 140)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            HapticManager.shared.playImpact(style: .light)
            viewModel.load(jobId: jobId)
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

    private func emptyStatePlaceholder(message: String) -> some View {
        Text(message)
            .scaledFont(size: 13, weight: .medium)
            .foregroundColor(settings.secondaryText.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(settings.surfaceColor.opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(settings.cardStroke, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            )
    }

    private func formattedTotal() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: viewModel.totalCost)) ?? "0"
    }

    private func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "LKR"
        formatter.locale = Locale(identifier: "en_LK")
        return formatter.string(from: NSNumber(value: value)) ?? "LKR \(String(format: "%.2f", value))"
    }
}

struct QuotationItemCard: View {
    var title: String
    var quantityText: String
    var priceText: String
    var statusText: String?
    var isApproved: Bool
    var removeAction: (() -> Void)?
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .scaledFont(size: 15, weight: .bold)
                    .foregroundColor(settings.primaryText)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(quantityText)
                        .scaledFont(size: 12, weight: .medium)
                        .foregroundColor(settings.secondaryText)
                    
                    Circle()
                        .fill(settings.secondaryText.opacity(0.3))
                        .frame(width: 3, height: 3)
                    
                    Text(priceText)
                        .scaledFont(size: 13, weight: .semibold)
                        .foregroundColor(settings.accentColor)
                }
            }

            Spacer()

            if let removeAction = removeAction {
                Button(action: {
                    HapticManager.shared.playImpact(style: .rigid)
                    removeAction()
                }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.red)
                        .frame(width: 36, height: 36)
                        .background(settings.isHighContrast ? Color.black : Color.red.opacity(0.08))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.red.opacity(0.1), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            } else if isApproved {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.green)
                    .shadow(color: Color.green.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
        .padding(20)
        .background(settings.surfaceColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    QuotationStatusView(jobId: "sample")
}
