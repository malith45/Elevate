import SwiftUI

struct InventoryView: View {
    let jobId: String

    @EnvironmentObject private var appSession: AppSession
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = InventoryViewModel()
    @ObservedObject private var network = NetworkService.shared
    @ObservedObject var settings = AccessibilitySettings.shared
    @State private var searchText: String = ""
    @State private var selectedTab: TabItem = .jobs
    @State private var navigateToQuotation = false
    
    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Inventory Selection")
                        .scaledFont(size: 28, weight: .bold, design: .rounded)
                        .foregroundColor(settings.primaryText)
                    Text("Browse and select equipment for this job")
                        .scaledFont(size: 15, weight: .medium)
                        .foregroundColor(settings.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)

                // Search Bar
                CustomSearchBar(text: $searchText, placeholder: "Search equipment...")
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        ForEach(groupedItems(), id: \.key) { category, items in
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text(category.uppercased())
                                        .scaledFont(size: 12, weight: .bold)
                                        .foregroundColor(settings.secondaryText)
                                        .tracking(1)
                                    Spacer()
                                    Text("\(items.count) AVAILABLE")
                                        .scaledFont(size: 10, weight: .bold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(settings.isHighContrast ? Color.black : settings.accentColor.opacity(0.1))
                                        .foregroundColor(settings.isHighContrast ? .white : settings.accentColor)
                                        .cornerRadius(4)
                                }

                                ForEach(items, id: \.id) { item in
                                    InventoryItemCard(
                                        icon: "cube.box",
                                        title: item.name,
                                        desc: item.category,
                                        price: currencyString(item.unitPrice),
                                        quantity: viewModel.quantity(for: item.id),
                                        imageUrl: item.imageUrl,
                                        onAdd: { 
                                            HapticManager.shared.playImpact(style: .light)
                                            viewModel.increment(itemId: item.id) 
                                        },
                                        onRemove: { 
                                            HapticManager.shared.playImpact(style: .light)
                                            viewModel.decrement(itemId: item.id) 
                                        }
                                    )
                                }
                            }
                        }

                        Spacer().frame(height: 140)
                    }
                    .padding(.horizontal, 24)
                }
                .safeAreaInset(edge: .bottom) {
                    requestQuotationBar
                }
                .refreshable {
                    if let user = appSession.currentUser {
                        viewModel.loadItems(organizationId: user.organizationId, isOnline: network.isOnline)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToQuotation) {
            QuotationStatusView(jobId: jobId)
        }
        .onAppear {
            HapticManager.shared.playImpact(style: .light)
            if let user = appSession.currentUser {
                viewModel.loadItems(organizationId: user.organizationId, isOnline: network.isOnline)
            }
        }
        .onChange(of: network.isOnline) { _, isOnline in
            if let user = appSession.currentUser {
                viewModel.loadItems(organizationId: user.organizationId, isOnline: isOnline)
            }
        }
        .alert("Inventory", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func groupedItems() -> [(key: String, value: [InventoryItem])] {
        let filtered = viewModel.items.filter {
            searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased())
        }
        let groups = Dictionary(grouping: filtered, by: { $0.category })
        return groups.sorted { $0.key < $1.key }
    }

    private func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "LKR"
        formatter.locale = Locale(identifier: "en_LK")
        return formatter.string(from: NSNumber(value: value)) ?? "LKR \(String(format: "%.2f", value))"
    }

    private var requestQuotationBar: some View {
        VStack(spacing: 0) {
            Divider().background(settings.cardStroke)
            
            VStack(spacing: 16) {
                Button(action: {
                    HapticManager.shared.playImpact(style: .medium)
                    submitQuotation()
                }) {
                    HStack {
                        Text("REQUEST QUOTATION")
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .scaledFont(size: 14, weight: .bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 24)
                    .background(settings.isHighContrast ? Color.black : Color.elevateDarkGreen)
                    .cornerRadius(14)
                    .shadow(color: Color.elevateDarkGreen.opacity(0.2), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 2)
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 140)
            .background(settings.appBackground)
        }
    }

    private func submitQuotation() {
        guard let user = appSession.currentUser else { return }
        viewModel.submitQuotationRequest(
            jobId: jobId,
            userId: user.id,
            organizationId: user.organizationId,
            isOnline: network.isOnline
        )
        viewModel.loadItems(organizationId: user.organizationId, isOnline: network.isOnline)
        navigateToQuotation = true
    }
}

struct InventoryItemCard: View {
    var icon: String
    var title: String
    var desc: String
    var price: String
    var quantity: Int
    var imageUrl: String?
    var onAdd: () -> Void
    var onRemove: () -> Void
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        HStack(spacing: 16) {
            inventoryImageView
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .scaledFont(size: 15, weight: .bold)
                    .foregroundColor(settings.primaryText)
                    .lineLimit(1)
                
                Text(desc)
                    .scaledFont(size: 11, weight: .medium)
                    .foregroundColor(settings.secondaryText)
                
                Text(price)
                    .scaledFont(size: 13, weight: .semibold)
                    .foregroundColor(settings.accentColor)
                    .padding(.top, 2)
            }
            
            Spacer()
            
            // Premium Stepper
            HStack(spacing: 12) {
                Button(action: onRemove) {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(quantity > 0 ? settings.primaryText : settings.secondaryText.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .background(settings.surfaceColor)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(settings.cardStroke, lineWidth: 1))
                }
                .disabled(quantity <= 0)
                
                Text("\(quantity)")
                    .scaledFont(size: 15, weight: .bold)
                    .foregroundColor(settings.primaryText)
                    .frame(minWidth: 20)
                    .multilineTextAlignment(.center)
                
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(settings.isHighContrast ? Color.black : Color.elevateDarkGreen)
                        .clipShape(Circle())
                        .shadow(color: Color.elevateDarkGreen.opacity(0.2), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(16)
        .background(settings.surfaceColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }

    private var inventoryImageView: some View {
        HighFidelityImageView(urlString: imageUrl, placeholderIcon: icon, cornerRadius: 12)
            .aspectRatio(1, contentMode: .fill)
            .frame(width: 64, height: 64)
            .clipped()
            .fixedSize()
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.5), lineWidth: 1))
    }

}

#Preview {
    InventoryView(jobId: "sample")
        .environmentObject(AppSession())
}
