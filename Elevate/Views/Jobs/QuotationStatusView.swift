import SwiftUI

struct QuotationStatusView: View {
    let jobId: String

    @Environment(\.presentationMode) var presentationMode
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
                        
                        Text("Quotation Status")
                            .scaledFont(size: 32, weight: .bold, design: .rounded)
                            .foregroundColor(settings.primaryText)
                        
                        // APPROVED ITEMS
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
                                    icon: "checkmark.circle",
                                    title: item.name,
                                    price: currencyString(Double(item.quantity) * item.unitPrice),
                                    statusText: item.status.uppercased(),
                                    isApproved: true
                                )
                            }
                        }
                        
                        // PENDING APPROVAL
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
                                    .background(settings.isHighContrast ? Color.black : Color.red.opacity(0.1))
                                    .foregroundColor(settings.isHighContrast ? .white : .red)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 1)
                                    )
                            }

                            ForEach(viewModel.pendingItems, id: \.id) { item in
                                QuotationItemCard(
                                    icon: "clock",
                                    title: item.name,
                                    price: currencyString(Double(item.quantity) * item.unitPrice),
                                    statusText: item.status.uppercased(),
                                    isApproved: false
                                )
                            }
                        }
                        
                        // Bottom Metrics + Action
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
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
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
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                )
                                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
                            }
                            
                            HStack(spacing: 16) {
                                Button(action: {}) {
                                    Text("CONFIRM")
                                        .scaledFont(size: 14, weight: .bold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(settings.isHighContrast ? Color.black : Color.elevateDarkGreen)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 2)
                                        )
                                }
                                
                                NavigationLink(destination: InventoryView(jobId: jobId)) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus.circle")
                                        Text("ADD ITEMS")
                                    }
                                    .scaledFont(size: 14, weight: .bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(settings.isHighContrast ? Color.black : Color.elevateDarkGreen)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 2)
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
    var icon: String
    var title: String
    var price: String
    var statusText: String
    var isApproved: Bool
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.elevateDarkGreen)
                .frame(width: 48, height: 48)
                .background(Color.elevateLightGray)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .scaledFont(size: 16, weight: .bold)
                    .foregroundColor(settings.primaryText)
                    .lineLimit(2)
                Text(price)
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundColor(settings.accentColor)
            }
            Spacer()
            
            Text(statusText)
                .scaledFont(size: 10, weight: .bold)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(settings.isHighContrast ? Color.black : (isApproved ? Color.green.opacity(0.2) : Color.red.opacity(0.1)))
                .foregroundColor(settings.isHighContrast ? Color.white : (isApproved ? Color.elevateDarkGreen : .red))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 1)
                )
        }
        .padding(20)
        .background(settings.surfaceColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    QuotationStatusView(jobId: "sample")
}
