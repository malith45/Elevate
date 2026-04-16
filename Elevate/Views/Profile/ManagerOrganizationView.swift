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
    private let localStorage = LocalStorageService.shared
    private let firebase = FirebaseService.shared

    var body: some View {
        ZStack {
            Color.elevateLightGray.opacity(0.3).ignoresSafeArea()

            VStack(spacing: 0) {
                BackHeaderNav(isManager: true, onBack: {
                    router.currentScreen = .profile
                    router.selectedTab = .profile
                })
                .background(Color.white)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("CORE IDENTITY")
                                    .scaledFont(size: 10, weight: .bold)
                                    .foregroundColor(.elevateTextGray)
                                Spacer()
                                Image(systemName: "checkmark.shield")
                                    .foregroundColor(.elevateTextGray)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("ORGANIZATION NAME")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(.elevateTextGray)
                                    Spacer()
                                    Button(action: {
                                        organizationNameDraft = organizationName
                                        isEditingName = true
                                    }) {
                                        Image(systemName: "square.and.pencil")
                                            .foregroundColor(.elevateTextGray)
                                    }
                                    .buttonStyle(.plain)
                                }
                                Text(organizationName)
                                    .scaledFont(size: 20, weight: .bold)
                                    .foregroundColor(.black)
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("INTRODUCTION")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(.elevateTextGray)
                                    Spacer()
                                    Button(action: {
                                        introductionDraft = introductionText
                                        isEditingIntroduction = true
                                    }) {
                                        Image(systemName: "square.and.pencil")
                                            .foregroundColor(.elevateTextGray)
                                    }
                                    .buttonStyle(.plain)
                                }
                                Text(introductionText)
                                    .scaledFont(size: 14)
                                    .foregroundColor(.elevateTextGray)
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)

                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("ORGANIZATION CODE")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(.elevateTextGray)
                                    Text(organizationCode)
                                        .scaledFont(size: 16, weight: .bold)
                                        .foregroundColor(.black)
                                }
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.elevateTextGray)
                            }
                            .padding(16)
                            .background(Color.elevateLightGray)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 16) {
                            Text("ECOSYSTEM VITALITY")
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(.elevateTextGray)

                            HStack(spacing: 16) {
                                metricCard(title: "ACTIVE MEMBERS", value: "\(activeMembersCount)", icon: "person.2")
                                metricCard(title: "MANAGEMENT", value: "\(managementCount)", icon: "person.3")
                            }

                            Button(action: {
                                router.currentScreen = .members
                                router.selectedTab = .profile
                            }) {
                                HStack(spacing: 12) {
                                    Text("Manage Members")
                                        .scaledFont(size: 14, weight: .bold)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                                .background(Color.elevateDarkGreen)
                                .cornerRadius(16)
                                .shadow(color: Color.elevateDarkGreen.opacity(0.25), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 96)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            guard let user = appSession.currentUser else { return }
            if viewModel.organizationName.isEmpty {
                viewModel.organizationName = user.organizationId
            }
            viewModel.load(organizationId: user.organizationId, isOnline: NetworkService.shared.isOnline)
            refreshMemberMetrics(organizationId: user.organizationId)
        }
        .onChange(of: network.isOnline) { _, _ in
            if let user = appSession.currentUser {
                refreshMemberMetrics(organizationId: user.organizationId)
            }
        }
        .alert("Edit Organization Name", isPresented: $isEditingName) {
            TextField("Organization Name", text: $organizationNameDraft)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                guard let user = appSession.currentUser else { return }
                viewModel.organizationName = organizationNameDraft
                viewModel.save(organizationId: user.organizationId, name: organizationNameDraft, introduction: nil)
            }
        }
        .alert("Edit Introduction", isPresented: $isEditingIntroduction) {
            TextField("Introduction", text: $introductionDraft)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
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
        return appSession.currentUser?.organizationId ?? "Skyline Corp"
    }

    private var introductionText: String {
        if !viewModel.introduction.isEmpty {
            return viewModel.introduction
        }
        return "Manage your organization profile, members, and permissions from this hub."
    }

    private var organizationCode: String {
        if let user = appSession.currentUser {
            return user.organizationId
        }
        return "ORG-1024-SV"
    }

    private func metricCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.elevateLightGray)
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .foregroundColor(.elevateDarkGreen)
            }
            Text(value)
                .scaledFont(size: 28, weight: .bold)
                .foregroundColor(.black)
            Text(title)
                .scaledFont(size: 10, weight: .bold)
                .foregroundColor(.elevateTextGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)
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
