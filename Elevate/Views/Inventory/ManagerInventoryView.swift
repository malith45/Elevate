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
                // Modified Header Section
                VStack(alignment: .leading, spacing: 20) {
                    BackHeaderNav(isManager: true, onBack: {
                        router.currentScreen = .dashboard
                        router.selectedTab = .dashboard
                    })
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Inventory Fleet")
                            .scaledFont(size: 28, weight: .bold, design: .rounded)
                            .foregroundColor(settings.primaryText)
                        Text("Manage region-wide assets and stock levels")
                            .scaledFont(size: 14, weight: .medium)
                            .foregroundColor(settings.secondaryText)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 24)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        searchBar

                        // Redesigned Stats Dashboard
                        HStack(spacing: 16) {
                            statCard(title: "TOTAL ASSETS", value: "\(viewModel.items.count)", icon: "shippingbox.fill", color: settings.accentColor)
                            statCard(title: "LOW STOCK", value: "\(criticalItems.count)", icon: "exclamationmark.triangle.fill", color: .red)
                        }
                        .padding(.horizontal, 24)

                        // Improved Grouped List
                        ForEach(groupedItems(), id: \.key) { category, items in
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(alignment: .lastTextBaseline) {
                                    Text(category.uppercased())
                                        .scaledFont(size: 11, weight: .black)
                                        .foregroundColor(settings.secondaryText.opacity(0.8))
                                        .tracking(1.2)
                                    
                                    Spacer()
                                    
                                    Text("\(items.count) UNITS")
                                        .scaledFont(size: 10, weight: .bold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(settings.isHighContrast ? settings.surfaceColor : settings.accentColor.opacity(0.1))
                                        .foregroundColor(settings.isHighContrast ? settings.primaryText : settings.accentColor)
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                        )
                                }
                                .padding(.horizontal, 8)

                                ForEach(items, id: \.id) { item in
                                    inventoryRow(item)
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        Spacer().frame(height: 120)
                    }
                    .padding(.top, 12)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 40)
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
                    .background(settings.isHighContrast ? settings.surfaceColor : Color.elevateDarkGreen)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
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

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(color)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(settings.secondaryText.opacity(0.3))
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .scaledFont(size: 20, weight: .bold, design: .rounded)
                    .foregroundColor(settings.primaryText)
                Text(title)
                    .scaledFont(size: 8, weight: .black)
                    .foregroundColor(settings.secondaryText)
                    .tracking(0.5)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(settings.surfaceColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private func inventoryRow(_ item: InventoryItem) -> some View {
        let status = stockStatus(for: item.quantity)

        return Button(action: {
            editingItem = item
            isEditorPresented = true
        }) {
            HStack(spacing: 12) {
                inventoryImageView(urlString: item.imageUrl)
                
                Text(item.name)
                    .scaledFont(size: 16, weight: .bold)
                    .foregroundColor(settings.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .layoutPriority(1)
                
                Spacer(minLength: 12)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(currencyString(item.unitPrice))
                        .scaledFont(size: 14, weight: .bold)
                        .foregroundColor(settings.primaryText)
                        .fixedSize()
                    
                    HStack(spacing: 4) {
                        Text("\(item.quantity)")
                            .scaledFont(size: 9, weight: .black)
                        Text(status.label)
                            .scaledFont(size: 9, weight: .bold)
                    }
                    .foregroundColor(status.foreground)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(status.background)
                    .cornerRadius(6)
                    .fixedSize()
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(settings.secondaryText.opacity(0.3))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(settings.surfaceColor)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func currencyString(_ value: Double?) -> String {
        guard let value = value else { return "LKR 0.00" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "LKR"
        formatter.locale = Locale(identifier: "en_LK")
        return formatter.string(from: NSNumber(value: value)) ?? "LKR \(String(format: "%.2f", value))"
    }

    private func groupedItems() -> [(key: String, value: [InventoryItem])] {
        let filtered = viewModel.items.filter {
            searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased())
        }
        let groups = Dictionary(grouping: filtered, by: { $0.category })
        return groups.sorted { $0.key < $1.key }
    }

    private var criticalItems: [InventoryItem] {
        viewModel.items.filter { $0.quantity < 5 }
    }

    private func stockStatus(for quantity: Int) -> (label: String, background: Color, foreground: Color) {
        if quantity < 5 {
            return ("LOW STOCK", Color.red.opacity(0.1), .red)
        }
        return ("IN STOCK", Color.elevateLightGray, .elevateDarkGreen)
    }

    private func inventoryImageView(urlString: String?) -> some View {
        HighFidelityImageView(urlString: urlString, placeholderIcon: "cube.box", cornerRadius: 14)
            .frame(width: 56, height: 56)
            .fixedSize()
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(settings.cardStroke, lineWidth: 1))
    }

    private func imageFromBase64(_ base64String: String) -> UIImage? {
        let components = base64String.components(separatedBy: ",")
        let cleanString = components.count > 1 ? components[1] : components[0]
        if let data = Data(base64Encoded: cleanString) {
            return UIImage(data: data)
        }
        return nil
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
    @ObservedObject var settings = AccessibilitySettings.shared

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
        ZStack {
            settings.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Content
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item == nil ? "Add New Item" : "Edit Item")
                                .scaledFont(size: 28, weight: .bold, design: .rounded)
                                .foregroundColor(settings.primaryText)
                            Text(item == nil ? "Create a new entry in your regional inventory" : "Update details for \(name)")
                                .scaledFont(size: 14, weight: .medium)
                                .foregroundColor(settings.secondaryText)
                        }
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(settings.secondaryText.opacity(0.5))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Photo Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("ITEM PHOTOGRAPH")
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(settings.secondaryText)
                                .padding(.horizontal, 4)
                            
                            HStack(spacing: 20) {
                                photoPreview
                                
                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(selectedPhotoData == nil ? "Add Photo" : "Replace Photo")
                                            .scaledFont(size: 14, weight: .bold)
                                            .foregroundColor(settings.accentColor)
                                        Text("JPG, PNG up to 5MB")
                                            .scaledFont(size: 11)
                                            .foregroundColor(settings.secondaryText)
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(settings.surfaceColor)
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth))
                        
                        // Identity Card
                        VStack(alignment: .leading, spacing: 20) {
                            Text("IDENTIFICATION")
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(settings.secondaryText)
                                .padding(.horizontal, 4)
                            
                            CustomTextField(title: "Item Name", placeholder: "e.g. Copper Pipe 15mm", iconName: "tag", text: $name)
                            CustomTextField(title: "Category", placeholder: "e.g. Plumbing", iconName: "folder", text: $category)
                            CustomTextField(title: "SKU / Reference", placeholder: "e.g. CP-15-001", iconName: "barcode", text: $sku)
                        }
                        .padding(20)
                        .background(settings.surfaceColor)
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth))
                        
                        // Commercial Card
                        VStack(alignment: .leading, spacing: 20) {
                            Text("COMMERCIALS & STOCK")
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(settings.secondaryText)
                                .padding(.horizontal, 4)
                            
                            HStack(spacing: 16) {
                                CustomTextField(title: "Price (LKR)", placeholder: "0.00", iconName: "dollarsign.circle", text: $unitPriceText)
                                CustomTextField(title: "Quantity", placeholder: "0", iconName: "box.truck", text: $quantityText)
                            }
                        }
                        .padding(20)
                        .background(settings.surfaceColor)
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth))
                        
                        if item != nil {
                            Button(action: { isDeleteAlertPresented = true }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete from Inventory")
                                }
                                .scaledFont(size: 14, weight: .bold)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .padding(.top, 8)
                        }
                        
                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 24)
                }
                .safeAreaInset(edge: .bottom) {
                    bottomActionBar
                }
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
            Text("This will permanently remove \(name) from the system.")
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        selectedPhotoData = data
                    }
                }
            }
        }
    }

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider().background(settings.cardStroke)
            HStack(spacing: 16) {
                SecondaryButton(title: "Cancel") {
                    dismiss()
                }
                
                PrimaryButton(title: item == nil ? "CREATE ITEM" : "SAVE CHANGES") {
                    HapticManager.shared.playImpact(style: .medium)
                    save()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 34)
            .background(settings.surfaceColor)
        }
    }

    private var photoPreview: some View {
        ZStack {
            if let selectedPhotoData, let uiImage = UIImage(data: selectedPhotoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipped()
                    .fixedSize()
            } else {
                HighFidelityImageView(urlString: item?.imageUrl, placeholderIcon: "camera.fill", cornerRadius: 16)
                    .frame(width: 80, height: 80)
            }
        }
        .frame(width: 80, height: 80)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(settings.cardStroke, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
    }

    private func imageFromBase64(_ base64String: String) -> UIImage? {
        let components = base64String.components(separatedBy: ",")
        let cleanString = components.count > 1 ? components[1] : components[0]
        if let data = Data(base64Encoded: cleanString) {
            return UIImage(data: data)
        }
        return nil
    }

    private var photoPlaceholder: some View {
        ZStack {
            Color.elevateLightGray.opacity(0.5)
            Image(systemName: "camera.fill")
                .foregroundColor(settings.secondaryText.opacity(0.5))
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
