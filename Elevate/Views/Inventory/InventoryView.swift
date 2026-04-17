import SwiftUI

struct InventoryView: View {
    let jobId: String

    @EnvironmentObject private var appSession: AppSession
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = InventoryViewModel()
    @ObservedObject private var network = NetworkService.shared
    @State private var searchText: String = ""
    @State private var selectedTab: TabItem = .jobs
    @State private var navigateToQuotation = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav()
                
                // Search Bar
                CustomSearchBar(text: $searchText, placeholder: "Search")
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(groupedItems(), id: \.key) { category, items in
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text(category.uppercased())
                                        .scaledFont(size: 12, weight: .bold)
                                        .foregroundColor(.elevateTextGray)
                                    Spacer()
                                    Text("\(items.count) ITEMS AVAILABLE")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(.elevateTextGray)
                                }

                                ForEach(items, id: \.id) { item in
                                    InventoryItemCard(
                                        icon: "cube.box",
                                        title: item.name,
                                        desc: item.category,
                                        price: currencyString(item.unitPrice),
                                        quantity: viewModel.quantity(for: item.id),
                                        onAdd: { viewModel.increment(itemId: item.id) },
                                        onRemove: { viewModel.decrement(itemId: item.id) }
                                    )
                                }
                            }
                        }

                        Button(action: submitQuotation) {
                            Text("REQUEST QUOTATION")
                                .scaledFont(size: 14, weight: .bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.elevateDarkGreen)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 24)

                        EmptyView()
                        
                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 24)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 96)
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
        return formatter.string(from: NSNumber(value: value)) ?? "LKR \(value)"
    }

    private func submitQuotation() {
        guard let user = appSession.currentUser else { return }
        viewModel.submitQuotationRequest(
            jobId: jobId,
            userId: user.id,
            organizationId: user.organizationId,
            isOnline: network.isOnline
        )
        navigateToQuotation = true
    }
}

struct InventoryItemCard: View {
    var icon: String
    var title: String
    var desc: String
    var price: String
    var quantity: Int
    var onAdd: () -> Void
    var onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.gray)
                .frame(width: 60, height: 60)
                .background(Color.elevateLightGray.opacity(0.5))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .scaledFont(size: 16, weight: .bold)
                Text(desc)
                    .scaledFont(size: 12)
                    .foregroundColor(.gray)
                Text(price)
                    .scaledFont(size: 14, weight: .bold)
                    .foregroundColor(.elevateDarkGreen)
                    .padding(.top, 4)
            }
            
            Spacer()
            
            // Stepper
            HStack(spacing: 0) {
                Button(action: {
                    onRemove()
                }) {
                    Image(systemName: "minus")
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                }
                
                Text("\(quantity)")
                    .scaledFont(size: 14, weight: .bold)
                    .frame(width: 24)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    onAdd()
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.elevateDarkGreen)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.elevateLightGray, lineWidth: 1))
            .cornerRadius(6)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    InventoryView(jobId: "sample")
        .environmentObject(AppSession())
}
