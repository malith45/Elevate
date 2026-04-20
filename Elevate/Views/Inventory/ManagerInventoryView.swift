import SwiftUI

struct ManagerInventoryView: View {
    @Environment(\.managerTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = InventoryViewModel()
    @ObservedObject private var network = NetworkService.shared
    @ObservedObject var settings = AccessibilitySettings.shared
    @State private var searchText = ""
    @State private var isEditorPresented = false
    @State private var editingItem: InventoryItem?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            settings.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                BackHeaderNav(isManager: true, onBack: {
                    router.currentScreen = .jobs
                    router.selectedTab = .jobs
                })

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        searchBar

                        HStack(spacing: 16) {
                            statCard(title: "TOTAL ITEMS", value: "\(viewModel.items.count)", valueColor: settings.accentColor)
                            statCard(title: "CRITICAL STOCK", value: "\(criticalItems.count)", valueColor: .red)
                        }
                        .padding(.horizontal, 24)

                        ForEach(groupedItems(), id: \.key) { category, items in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(category.uppercased())
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(settings.accentColor)
                                    Spacer()
                                    Text("\(items.count) ITEMS")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(settings.secondaryText)
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
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 96)
                }
                .refreshable {
                    if let user = appSession.currentUser {
                        viewModel.loadItems(organizationId: user.organizationId, isOnline: network.isOnline)
                    }
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
                    .background(settings.isHighContrast ? Color.black : Color.elevateDarkGreen)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 24)
            .padding(.bottom, 110)
        }
        .navigationBarHidden(true)
        .speakOnAppear("Inventory Management Dashboard")
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
                    ) { _ in
                        viewModel.loadItems(organizationId: user.organizationId, isOnline: network.isOnline)
                    }
                } else {
                    viewModel.createItem(
                        organizationId: user.organizationId,
                        name: draft.name,
                        category: draft.category,
                        quantity: draft.quantity,
                        unitPrice: draft.unitPrice,
                        sku: draft.sku,
                        isOnline: network.isOnline
                    ) { _ in
                        viewModel.loadItems(organizationId: user.organizationId, isOnline: network.isOnline)
                    }
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
        CustomSearchBar(text: $searchText, placeholder: "Search inventory...")
        .padding(.horizontal, 24)
    }

    private func statCard(title: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .scaledFont(size: 10, weight: .bold)
                .foregroundColor(settings.secondaryText)
            Text(value)
                .scaledFont(size: 22, weight: .bold)
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(settings.surfaceColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
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
                    .foregroundColor(settings.primaryText)
                    .lineLimit(1)
                Text("SKU: \(skuText)")
                    .scaledFont(size: 10)
                    .foregroundColor(settings.secondaryText)
                Text("\(item.quantity) units")
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundColor(settings.accentColor)
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
                    .foregroundColor(settings.secondaryText)
                    .frame(width: 32, height: 32)
                    .background(settings.isHighContrast ? Color.black : Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(settings.cardStroke, lineWidth: settings.isHighContrast ? 1 : 0)
                    )
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(settings.surfaceColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
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
