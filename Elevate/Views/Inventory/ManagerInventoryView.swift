import SwiftUI
import PhotosUI
import UIKit

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
            .padding(.bottom, 24)
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
            InventoryEditorView(item: editingItem, onDelete: { item in
                guard let user = appSession.currentUser else { return }
                viewModel.deleteItem(item, userId: user.id, isOnline: network.isOnline) { _ in
                    viewModel.loadItems(organizationId: user.organizationId, isOnline: network.isOnline)
                }
            }) { draft in
                guard let user = appSession.currentUser else { return }
                if let item = editingItem {
                    viewModel.updateItem(
                        item,
                        userId: user.id,
                        name: draft.name,
                        category: draft.category,
                        quantity: draft.quantity,
                        unitPrice: draft.unitPrice,
                        sku: draft.sku,
                        imageUrl: draft.imageUrl,
                        imageData: draft.imageData,
                        isOnline: network.isOnline
                    ) { _ in
                        viewModel.loadItems(organizationId: user.organizationId, isOnline: network.isOnline)
                    }
                } else {
                    viewModel.createItem(
                        organizationId: user.organizationId,
                        userId: user.id,
                        name: draft.name,
                        category: draft.category,
                        quantity: draft.quantity,
                        unitPrice: draft.unitPrice,
                        sku: draft.sku,
                        imageData: draft.imageData,
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
            inventoryImageView(urlString: item.imageUrl)

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

    private func inventoryImageView(urlString: String?) -> some View {
        let frame = CGSize(width: 56, height: 56)
        if let urlString = urlString, let url = URL(string: urlString) {
            return AnyView(
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderImage
                    case .empty:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
                .frame(width: frame.width, height: frame.height)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            )
        }

        return AnyView(
            placeholderImage
                .frame(width: frame.width, height: frame.height)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        )
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.elevateLightGray.opacity(0.8))
            .overlay(
                Image(systemName: "cube.box")
                    .foregroundColor(.elevateDarkGreen)
            )
    }
}

private struct InventoryEditorDraft {
    var name: String
    var category: String
    var quantity: Int
    var unitPrice: Double
    var sku: String?
    var imageUrl: String?
    var imageData: Data?
}

private struct InventoryEditorView: View {
    let item: InventoryItem?
    var onDelete: ((InventoryItem) -> Void)?
    var onSave: (InventoryEditorDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var category: String
    @State private var quantityText: String
    @State private var unitPriceText: String
    @State private var sku: String
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var isDeleteAlertPresented = false

    init(item: InventoryItem?, onDelete: ((InventoryItem) -> Void)? = nil, onSave: @escaping (InventoryEditorDraft) -> Void) {
        self.item = item
        self.onDelete = onDelete
        self.onSave = onSave
        _name = State(initialValue: item?.name ?? "")
        _category = State(initialValue: item?.category ?? "")
        _quantityText = State(initialValue: item.map { String($0.quantity) } ?? "0")
        _unitPriceText = State(initialValue: item.map { String(format: "%.2f", $0.unitPrice) } ?? "")
        _sku = State(initialValue: item?.sku ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("DETAILS")) {
                    TextField("Name", text: $name)
                    TextField("Category", text: $category)
                    TextField("SKU", text: $sku)
                    TextField("Unit Price (LKR)", text: $unitPriceText)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("PHOTO")) {
                    HStack(spacing: 16) {
                        photoPreview
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Text(selectedPhotoData == nil ? "Add Photo" : "Change Photo")
                        }
                    }
                }

                Section(header: Text("STOCK")) {
                    TextField("Quantity", text: $quantityText)
                        .keyboardType(.numberPad)
                }

                if item != nil {
                    Section {
                        Button(role: .destructive) {
                            isDeleteAlertPresented = true
                        } label: {
                            Text("Delete Item")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
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
            .alert("Delete Item", isPresented: $isDeleteAlertPresented) {
                Button("Delete", role: .destructive) {
                    guard let item = item else { return }
                    onDelete?(item)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove the item from inventory.")
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else {
                    selectedPhotoData = nil
                    return
                }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            selectedPhotoData = data
                        }
                    }
                }
            }
        }
    }

    private var photoPreview: some View {
        let size = CGSize(width: 64, height: 64)
        if let selectedPhotoData, let uiImage = UIImage(data: selectedPhotoData) {
            return AnyView(
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            )
        }

        if let urlString = item?.imageUrl, let url = URL(string: urlString) {
            return AnyView(
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        photoPlaceholder
                    case .empty:
                        photoPlaceholder
                    @unknown default:
                        photoPlaceholder
                    }
                }
                .frame(width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            )
        }

        return AnyView(
            photoPlaceholder
                .frame(width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        )
    }

    private var photoPlaceholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.elevateLightGray.opacity(0.6))
            .overlay(
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            )
    }

    private func save() {
        let quantity = Int(quantityText) ?? 0
        let unitPrice = Double(unitPriceText) ?? 0
        let draft = InventoryEditorDraft(
            name: name,
            category: category,
            quantity: quantity,
            unitPrice: unitPrice,
            sku: sku.isEmpty ? nil : sku,
            imageUrl: item?.imageUrl,
            imageData: selectedPhotoData
        )
        onSave(draft)
        dismiss()
    }
}

#Preview {
    ManagerInventoryView()
        .environmentObject(AppSession())
}
