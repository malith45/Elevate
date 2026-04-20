import SwiftUI

struct QuotationStatusView: View {
    let jobId: String

    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = QuotationStatusViewModel()
    @ObservedObject var settings = AccessibilitySettings.shared
    @State private var selectedTab: TabItem = .jobs
    
    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Quotation Status")
                                .scaledFont(size: 28, weight: .bold, design: .rounded)
                                .foregroundColor(settings.primaryText)
                            Text("Track approved and pending items")
                                .scaledFont(size: 13, weight: .semibold)
                                .foregroundColor(settings.secondaryText)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("APPROVED ITEMS")
                                    .scaledFont(size: 12, weight: .bold)
                                    .foregroundColor(settings.secondaryText)
                                Spacer()
                                Text("\(viewModel.approvedItems.count) ITEMS")
                                    .scaledFont(size: 10, weight: .bold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(settings.isHighContrast ? Color.black : Color.green.opacity(0.2))
                                    .foregroundColor(settings.isHighContrast ? .white : .green)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 1)
                                    )
                            }

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
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("PENDING APPROVAL")
                                    .scaledFont(size: 12, weight: .bold)
                                    .foregroundColor(settings.secondaryText)
                                Spacer()
                                Text("\(viewModel.pendingItems.count) ITEMS")
                                    .scaledFont(size: 10, weight: .bold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(settings.isHighContrast ? Color.black : Color.orange.opacity(0.15))
                                    .foregroundColor(settings.isHighContrast ? .white : .orange)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 1)
                                    )
                            }

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

                        if !viewModel.rejectedItems.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("REJECTED ITEMS")
                                        .scaledFont(size: 12, weight: .bold)
                                        .foregroundColor(settings.secondaryText)
                                    Spacer()
                                    Text("\(viewModel.rejectedItems.count) ITEMS")
                                        .scaledFont(size: 10, weight: .bold)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(settings.isHighContrast ? Color.black : Color.red.opacity(0.15))
                                        .foregroundColor(settings.isHighContrast ? .white : .red)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 1)
                                        )
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
                        
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("TOTAL VALUE")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(settings.isHighContrast ? .white : .white.opacity(0.8))
                                    Text("LKR\n\(formattedTotal())")
                                        .scaledFont(size: 28, weight: .bold)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                                .background(settings.isHighContrast ? Color.black : Color.elevateDarkGreen)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                )
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("ITEMS ORDERED")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(settings.secondaryText)
                                    Text("\(viewModel.items.count)")
                                        .scaledFont(size: 28, weight: .bold)
                                        .foregroundColor(settings.accentColor)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                                .background(settings.surfaceColor)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                )
                                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
                            }
                            
                            HStack(spacing: 12) {
                                Button(action: {}) {
                                    Text("CONFIRM")
                                        .scaledFont(size: 14, weight: .bold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(settings.isHighContrast ? Color.black : Color.elevateDarkGreen)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 2)
                                        )
                                }

                                NavigationLink(destination: InventoryView(jobId: jobId)) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus.circle")
                                        Text("ADD ITEMS")
                                    }
                                    .scaledFont(size: 14, weight: .bold)
                                    .foregroundColor(settings.accentColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(settings.surfaceColor)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                    )
                                }
                            }
                        }
                        .padding(.top, 16)
                        
                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 24)
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
        return formatter.string(from: NSNumber(value: value)) ?? "LKR \(value)"
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
        HStack(spacing: 12) {
            Text(title)
                .scaledFont(size: 14, weight: .bold)
                .foregroundColor(settings.primaryText)
                .lineLimit(1)

            Spacer()

            HStack(spacing: 12) {
                Text(quantityText)
                    .scaledFont(size: 11, weight: .semibold)
                    .foregroundColor(settings.secondaryText)
                Text(priceText)
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundColor(settings.accentColor)
            }

            if let removeAction = removeAction {
                Button(action: removeAction) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                        .frame(width: 28, height: 28)
                        .background(settings.isHighContrast ? Color.black : Color.red.opacity(0.12))
                        .cornerRadius(8)
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
}

#Preview {
    QuotationStatusView(jobId: "sample")
}
