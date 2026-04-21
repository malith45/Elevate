import SwiftUI

struct ManagerMemberDetailView: View {
    let memberId: String

    @Environment(\.managerTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @State private var member: User?
    @State private var editingMember: User?
    @State private var errorMessage: String?
    @ObservedObject private var network = NetworkService.shared
    @ObservedObject var settings = AccessibilitySettings.shared

    private let localStorage = LocalStorageService.shared
    private let firebase = FirebaseService.shared

    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                BackHeaderNav(isManager: true, onBack: {
                    router.currentScreen = .members
                    router.selectedTab = .profile
                })
                .background(settings.surfaceColor)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        headerCard

                        detailsCard

                        PrimaryButton(title: "Edit Member", iconName: nil) {
                            editingMember = member
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 12)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 96)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadMember()
        }
        .onChange(of: network.isOnline) { _, _ in
            loadMember()
        }
        .sheet(item: $editingMember) { editMember in
            MemberEditorView(member: editMember, onSave: { draft in
                updateMember(editMember, draft: draft)
            }, onDelete: {
                let viewModel = ManagerMembersViewModel()
                guard let user = appSession.currentUser else { return }
                viewModel.deleteMember(editMember, actorUserId: user.id, isOnline: network.isOnline) { success in
                    if success {
                        router.currentScreen = .members
                    }
                }
            })
        }
        .alert("Member", isPresented: Binding(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var headerCard: some View {
        VStack(spacing: 12) {
            if let member = member {
                ProfilePhotoView(userId: member.id, size: 80)
            } else {
                Circle()
                    .fill(settings.surfaceColor)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle().stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                    )
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .foregroundColor(settings.primaryText)
                    )
            }

            Text(displayName)
                .scaledFont(size: 22, weight: .bold, design: .rounded)
                .foregroundColor(settings.primaryText)

            Text("ID: \(shortId)")
                .scaledFont(size: 12, weight: .bold)
                .foregroundColor(settings.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(settings.isHighContrast ? Color.black : Color.elevateLightGray)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                )
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(settings.surfaceColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)
        .padding(.horizontal, 24)
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            detailRow(label: "Role", value: member?.role.capitalized ?? "-")
            detailRow(label: "Email", value: member?.email ?? "-")
            detailRow(label: "Phone", value: member?.phone ?? "-")
        }
        .padding(20)
        .background(settings.surfaceColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)
        .padding(.horizontal, 24)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label.uppercased())
                .scaledFont(size: 10, weight: .bold)
                .foregroundColor(settings.secondaryText)
            Spacer()
            Text(value)
                .scaledFont(size: 12, weight: .bold)
                .foregroundColor(settings.primaryText)
        }
    }

    private var displayName: String {
        let name = member?.displayName
        if let name, !name.isEmpty {
            return name
        }
        return member?.username ?? "Member"
    }

    private var shortId: String {
        String((member?.id ?? memberId).prefix(6))
    }

    private func loadMember() {
        member = localStorage.fetchUser(id: memberId)
        ProfileImageSync.shared.syncProfilePhotoUrl(userId: memberId)

        guard network.isOnline else { return }
        firebase.fetchUser(userId: memberId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self.localStorage.saveUsers([user])
                    self.member = user
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func updateMember(_ member: User, draft: MemberEditorDraft) {
        let viewModel = ManagerMembersViewModel()
        guard let user = appSession.currentUser else { return }
        viewModel.updateMember(
            member,
            actorUserId: user.id,
            displayName: draft.displayName,
            role: draft.role,
            email: draft.email,
            phone: draft.phone,
            password: draft.password,
            profileImage: draft.profileImage,
            isOnline: network.isOnline
        )
        loadMember()
    }
}

#Preview {
    ManagerMemberDetailView(memberId: "sample")
        .environmentObject(AppSession())
}
