import SwiftUI

struct ManagerMembersView: View {
    @Environment(\.managerTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = ManagerMembersViewModel()
    @State private var isEditorPresented = false
    @State private var editingMember: User?

    var body: some View {
        ZStack {
            Color.elevateLightGray.opacity(0.3).ignoresSafeArea()

            VStack(spacing: 0) {
                BackHeaderNav(isManager: true, onBack: {
                    router.currentScreen = .organization
                    router.selectedTab = .profile
                })
                .background(Color.white)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        searchBar

                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Members")
                                    .scaledFont(size: 22, weight: .bold, design: .rounded)
                                Text("\(viewModel.members.count) Active")
                                    .scaledFont(size: 12)
                                    .foregroundColor(.elevateTextGray)
                            }

                            Spacer()

                            Button(action: {
                                router.currentScreen = .addMember
                                router.selectedTab = .profile
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.badge.plus")
                                    Text("Add New")
                                }
                                .scaledFont(size: 12, weight: .bold)
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                                .background(Color.elevateDarkGreen)
                                .cornerRadius(12)
                                .shadow(color: Color.elevateDarkGreen.opacity(0.25), radius: 6, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)

                        VStack(spacing: 12) {
                            ForEach(viewModel.members) { member in
                                Button(action: {
                                    router.selectedMemberId = member.id
                                    router.currentScreen = .memberDetails
                                    router.selectedTab = .profile
                                }) {
                                    memberRow(member)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
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
            guard let user = appSession.currentUser else { return }
            viewModel.load(organizationId: user.organizationId, isOnline: NetworkService.shared.isOnline)
        }
        .alert("Members", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $isEditorPresented) {
            if let member = editingMember {
                MemberEditorView(member: member) { draft in
                    viewModel.updateMember(
                        member,
                        displayName: draft.displayName,
                        role: draft.role,
                        email: draft.email,
                        phone: draft.phone,
                        isOnline: NetworkService.shared.isOnline
                    )
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.elevateTextGray)
            Text("Search")
                .scaledFont(size: 14)
                .foregroundColor(.elevateTextGray)
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 24)
    }

    private func memberRow(_ member: User) -> some View {
        let name = member.displayName.isEmpty ? member.username : member.displayName
        let role = member.role.isEmpty ? "Member" : member.role.capitalized
        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.elevateLightGray)
                    .frame(width: 52, height: 52)
                Image(systemName: "person")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.elevateDarkGreen)
            }
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.elevateDarkGreen)
                    .frame(width: 10, height: 10)
                    .offset(x: 2, y: 2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .scaledFont(size: 14, weight: .bold)
                    .foregroundColor(.black)
                HStack(spacing: 6) {
                    Image(systemName: "briefcase")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.elevateTextGray)
                    Text(role)
                        .scaledFont(size: 10, weight: .medium)
                        .foregroundColor(.elevateTextGray)
                }
            }

            Spacer()

            Text(shortId(member.id))
                .scaledFont(size: 9, weight: .bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.elevateLightGray)
                .cornerRadius(6)
                .foregroundColor(.elevateTextGray)

            Button(action: {
                editingMember = member
                isEditorPresented = true
            }) {
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.elevateTextGray)
                    .frame(width: 28, height: 28)
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

    private func shortId(_ id: String) -> String {
        String(id.prefix(6))
    }
}

#Preview {
    ManagerMembersView()
        .environmentObject(AppSession())
}
