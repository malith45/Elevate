import SwiftUI

struct ManagerOrganizationView: View {
    @Environment(\.managerTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = ManagerOrganizationViewModel()
    @ObservedObject private var network = NetworkService.shared
    @State private var organizationNameDraft = ""
    @State private var introductionDraft = ""
    @State private var isEditingName = false
    @State private var isEditingIntroduction = false
    @State private var activeMembersCount = 0
    @State private var managementCount = 0
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settings = AccessibilitySettings.shared
    private let localStorage = LocalStorageService.shared
    private let firebase = FirebaseService.shared

    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                BackHeaderNav(isManager: true, onBack: {
                    dismiss()
                })
                .background(settings.appBackground)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // Header Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Organization")
                                .scaledFont(size: 28, weight: .bold, design: .rounded)
                                .foregroundColor(settings.primaryText)
                            Text("Manage your corporate identity and team metrics.")
                                .scaledFont(size: 14)
                                .foregroundColor(settings.secondaryText)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        // CORE IDENTITY SECTION
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("CORE IDENTITY")
                                    .scaledFont(size: 10, weight: .bold)
                                    .foregroundColor(settings.secondaryText)
                                    .tracking(1)
                                Spacer()
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.elevateDarkGreen)
                                Text("Verified")
                                    .scaledFont(size: 10, weight: .bold)
                                    .foregroundColor(.elevateDarkGreen)
                            }
                            .padding(.horizontal, 4)

                            VStack(spacing: 0) {
                                // Name Field
                                identityField(
                                    label: "ORGANIZATION NAME",
                                    value: organizationName,
                                    icon: "building.2",
                                    onEdit: {
                                        organizationNameDraft = organizationName
                                        isEditingName = true
                                    }
                                )
                                
                                Divider().padding(.leading, 50)
                                
                                // Introduction Field
                                identityField(
                                    label: "INTRODUCTION",
                                    value: introductionText,
                                    icon: "quote.opening",
                                    onEdit: {
                                        introductionDraft = introductionText
                                        isEditingIntroduction = true
                                    }
                                )
                            }
                            .background(settings.surfaceColor)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                            )
                            .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
                            
                            // Organization Code Badge
                            HStack(spacing: 12) {
                                Image(systemName: "qrcode.viewfinder")
                                    .foregroundColor(.elevateDarkGreen)
                                    .font(.system(size: 18, weight: .bold))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("ORGANIZATION CODE")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(settings.secondaryText)
                                    Text(organizationCode)
                                        .scaledFont(size: 15, weight: .bold, design: .monospaced)
                                        .foregroundColor(settings.primaryText)
                                }
                                Spacer()
                                Text("REG-CORE")
                                    .scaledFont(size: 8, weight: .black)
                                    .foregroundColor(.elevateDarkGreen.opacity(0.6))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.elevateDarkGreen.opacity(0.1))
                                    .cornerRadius(6)
                            }
                            .padding(16)
                            .background(settings.surfaceColor)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                            )
                            .shadow(color: Color.black.opacity(0.01), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal, 24)

                        // VITALITY SECTION (Metrics)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("ECOSYSTEM VITALITY")
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(settings.secondaryText)
                                .tracking(1)
                                .padding(.leading, 4)

                            HStack(spacing: 12) {
                                metricCard(title: "Active Personnel", value: "\(activeMembersCount)", icon: "person.2.fill")
                                metricCard(title: "Management Team", value: "\(managementCount)", icon: "shield.lefthalf.filled")
                            }

                            Button(action: {
                                router.path.append(ManagerScreen.members)
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "person.3.fill")
                                    Text("Manage Team Members")
                                        .scaledFont(size: 14, weight: .bold)
                                    Spacer()
                                    Image(systemName: "arrow.right.circle.fill")
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .background(Color.elevateDarkGreen)
                                .cornerRadius(16)
                                .shadow(color: Color.elevateDarkGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 24)

                        Spacer().frame(height: 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            guard let user = appSession.currentUser else { return }
            if viewModel.organizationName.isEmpty {
                // Do not assign ID to name, let it stay empty while loading
            }
            viewModel.load(organizationId: user.organizationId, isOnline: NetworkService.shared.isOnline)
            refreshMemberMetrics(organizationId: user.organizationId)
        }
        .onChange(of: network.isOnline) { _, _ in
            if let user = appSession.currentUser {
                refreshMemberMetrics(organizationId: user.organizationId)
            }
        }
        .sheet(isPresented: $isEditingName) {
            editorSheet(title: "Organization Name", text: $organizationNameDraft) {
                guard let user = appSession.currentUser else { return }
                viewModel.organizationName = organizationNameDraft
                viewModel.save(organizationId: user.organizationId, name: organizationNameDraft, introduction: nil)
            }
        }
        .sheet(isPresented: $isEditingIntroduction) {
            editorSheet(title: "Introduction", text: $introductionDraft) {
                guard let user = appSession.currentUser else { return }
                viewModel.introduction = introductionDraft
                viewModel.save(organizationId: user.organizationId, name: nil, introduction: introductionDraft)
            }
        }
        .alert("Organization", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var organizationName: String {
        if !viewModel.organizationName.isEmpty {
            return viewModel.organizationName
        }
        return ""
    }

    private var introductionText: String {
        if !viewModel.introduction.isEmpty {
            return viewModel.introduction
        }
        return ""
    }

    private var organizationCode: String {
        if let user = appSession.currentUser {
            return user.organizationId
        }
        return ""
    }

    // MARK: - Sub-views

    private func identityField(label: String, value: String, icon: String, onEdit: @escaping () -> Void) -> some View {
        Button(action: onEdit) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.elevateDarkGreen.opacity(0.1))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .foregroundColor(.elevateDarkGreen)
                        .font(.system(size: 14, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .scaledFont(size: 9, weight: .bold)
                        .foregroundColor(settings.secondaryText)
                        .tracking(0.5)
                    Text(value)
                        .scaledFont(size: 14, weight: .semibold)
                        .foregroundColor(settings.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Image(systemName: "pencil")
                    .foregroundColor(.elevateDarkGreen)
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 32, height: 32)
                    .background(Color.elevateDarkGreen.opacity(0.1))
                    .clipShape(Circle())
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }

    private func metricCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .center, spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.elevateDarkGreen.opacity(0.05))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundColor(.elevateDarkGreen)
                    .font(.system(size: 18, weight: .bold))
            }
            
            VStack(spacing: 2) {
                Text(value)
                    .scaledFont(size: 24, weight: .bold, design: .rounded)
                    .foregroundColor(settings.primaryText)
                Text(title)
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundColor(settings.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(settings.surfaceColor)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
    }

    private func editorSheet(title: String, text: Binding<String>, onSave: @escaping () -> Void) -> some View {
        let isIntro = title.lowercased().contains("introduction")
        
        return NavigationStack {
            VStack(spacing: 24) {
                if isIntro {
                    CustomTextEditor(title: title.uppercased(), placeholder: "Describe your organization...", iconName: "quote.opening", text: text)
                        .padding(.top, 32)
                } else {
                    CustomTextField(title: title.uppercased(), placeholder: "Enter \(title.lowercased())", iconName: "pencil.and.outline", text: text)
                        .padding(.top, 32)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle("Edit \(title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isEditingName = false; isEditingIntroduction = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        isEditingName = false
                        isEditingIntroduction = false
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.elevateDarkGreen)
                }
            }
        }
        .presentationDetents(isIntro ? [.medium, .large] : [.height(280)])
    }

    private func refreshMemberMetrics(organizationId: String) {
        let local = localStorage.fetchUsers(organizationId: organizationId)
        applyMemberMetrics(local)

        guard NetworkService.shared.isOnline else { return }
        firebase.fetchUsers(organizationId: organizationId) { result in
            if case .success(let users) = result {
                self.localStorage.saveUsers(users)
                DispatchQueue.main.async {
                    self.applyMemberMetrics(users)
                }
            }
        }
    }

    private func applyMemberMetrics(_ users: [User]) {
        activeMembersCount = users.filter { $0.role.uppercased() == "TECHNICIAN" }.count
        managementCount = users.filter { $0.role.uppercased() == "MANAGER" }.count
    }
}

#Preview {
    ManagerOrganizationView()
        .environmentObject(AppSession())
}
