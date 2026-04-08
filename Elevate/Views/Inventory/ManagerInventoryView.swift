import SwiftUI

struct ManagerInventoryView: View {
    @Environment(\.managerTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = InventoryViewModel()
    @ObservedObject private var network = NetworkService.shared
    @State private var searchText = ""
    @State private var isEditorPresented = false
    @State private var editingItem: InventoryItem?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                BackHeaderNav(isManager: true, onBack: {
                    router.currentScreen = .jobs
                    router.selectedTab = .jobs
                })

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        searchBar

                        HStack(spacing: 16) {
                            statCard(title: "TOTAL ITEMS", value: "\(viewModel.items.count)", valueColor: .elevateDarkGreen)
                            statCard(title: "CRITICAL STOCK", value: "\(criticalItems.count)", valueColor: .red)
                        }
                        .padding(.horizontal, 24)

                        ForEach(groupedItems(), id: \.key) { category, items in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(category.uppercased())
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(.elevateDarkGreen)
                                    Spacer()
                                    Text("\(items.count) ITEMS")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(.elevateTextGray)
                                }

                                ForEach(items, id: \.id) { item in
                                    inventoryRow(item)
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 12)
                }
            }

            Button(action: {
                editingItem = nil
                isEditorPresented = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.elevateDarkGreen)
                    .clipShape(Circle())
                    .shadow(color: Color.elevateDarkGreen.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 24)
            .padding(.bottom, 110)
        }
        .navigationBarHidden(true)
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
        .sheet(isPresented: $isEditorPresented) {
            InventoryEditorView(item: editingItem) { draft in
                guard let user = appSession.currentUser else { return }
                if let item = editingItem {
                    viewModel.updateItem(
                        item,
                        name: draft.name,
                        category: draft.category,
                        quantity: draft.quantity,
                        unitPrice: draft.unitPrice,
                        sku: draft.sku,
                        isOnline: network.isOnline
                    ) { _ in }
                } else {
                    viewModel.createItem(
                        organizationId: user.organizationId,
                        name: draft.name,
                        category: draft.category,
                        quantity: draft.quantity,
                        unitPrice: draft.unitPrice,
                        sku: draft.sku,
                        isOnline: network.isOnline
                    ) { _ in }
                }
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

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.elevateTextGray)
            TextField("Search inventory...", text: $searchText)
                .scaledFont(size: 14)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color.elevateLightGray.opacity(0.5))
        .cornerRadius(12)
        .padding(.horizontal, 24)
    }

    private func statCard(title: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .scaledFont(size: 10, weight: .bold)
                .foregroundColor(.elevateTextGray)
            Text(value)
                .scaledFont(size: 22, weight: .bold)
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)
    }

    private func inventoryRow(_ item: InventoryItem) -> some View {
        let status = stockStatus(for: item.quantity)

        return HStack(spacing: 12) {
            let skuText = item.sku ?? "N/A"
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.elevateLightGray.opacity(0.8))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "cube.box")
                        .foregroundColor(.elevateDarkGreen)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .scaledFont(size: 14, weight: .bold)
                    .lineLimit(1)
                Text("SKU: \(skuText)")
                    .scaledFont(size: 10)
                    .foregroundColor(.elevateTextGray)
                Text("\(item.quantity) units")
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundColor(.elevateDarkGreen)
            }

            Spacer()

            Text(status.label)
                .scaledFont(size: 9, weight: .bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(status.background)
                .foregroundColor(status.foreground)
                .cornerRadius(10)

            Button(action: {
                editingItem = item
                isEditorPresented = true
            }) {
                Image(systemName: "square.and.pencil")
                    .foregroundColor(.elevateTextGray)
                    .frame(width: 32, height: 32)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)
    }

    private func groupedItems() -> [(key: String, value: [InventoryItem])] {
        let filtered = viewModel.items.filter {
            searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased())
        }
        let groups = Dictionary(grouping: filtered, by: { $0.category })
        return groups.sorted { $0.key < $1.key }
    }

    private var criticalItems: [InventoryItem] {
        viewModel.items.filter { $0.quantity <= 3 }
    }

    private func stockStatus(for quantity: Int) -> (label: String, background: Color, foreground: Color) {
        if quantity <= 3 {
            return ("LOW STOCK", Color.red.opacity(0.1), .red)
        }
        return ("IN STOCK", Color.elevateLightGray, .elevateDarkGreen)
    }
}

private struct InventoryEditorDraft {
    var name: String
    var category: String
    var quantity: Int
    var unitPrice: Double
    var sku: String?
}

private struct InventoryEditorView: View {
    let item: InventoryItem?
    var onSave: (InventoryEditorDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var category: String
    @State private var quantityText: String
    @State private var unitPriceText: String
    @State private var sku: String

    init(item: InventoryItem?, onSave: @escaping (InventoryEditorDraft) -> Void) {
        self.item = item
        self.onSave = onSave
        _name = State(initialValue: item?.name ?? "")
        _category = State(initialValue: item?.category ?? "")
        _quantityText = State(initialValue: item.map { String($0.quantity) } ?? "0")
        _unitPriceText = State(initialValue: item.map { String(format: "%.2f", $0.unitPrice) } ?? "0")
        _sku = State(initialValue: item?.sku ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("DETAILS")) {
                    TextField("Name", text: $name)
                    TextField("Category", text: $category)
                    TextField("SKU", text: $sku)
                }

                Section(header: Text("STOCK")) {
                    TextField("Quantity", text: $quantityText)
                        .keyboardType(.numberPad)
                    TextField("Unit Price", text: $unitPriceText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle(item == nil ? "Add Item" : "Edit Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func save() {
        let quantity = Int(quantityText) ?? 0
        let unitPrice = Double(unitPriceText) ?? 0
        let draft = InventoryEditorDraft(
            name: name,
            category: category,
            quantity: quantity,
            unitPrice: unitPrice,
            sku: sku.isEmpty ? nil : sku
        )
        onSave(draft)
        dismiss()
    }
}

#Preview {
    ManagerInventoryView()
        .environmentObject(AppSession())
}
