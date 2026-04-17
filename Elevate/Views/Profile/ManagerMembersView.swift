import SwiftUI

struct ManagerMembersView: View {
    @Environment(\.managerTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = ManagerMembersViewModel()
    @State private var editingMember: User?
    @State private var searchText = ""

    var filteredMembers: [User] {
        if searchText.isEmpty { return viewModel.members }
        return viewModel.members.filter {
            let name = $0.displayName.isEmpty ? $0.username : $0.displayName
            return name.localizedCaseInsensitiveContains(searchText) ||
                   $0.role.localizedCaseInsensitiveContains(searchText)
        }
    }

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
                                Text("\(filteredMembers.count) Active")
                                    .scaledFont(size: 12)
                                    .foregroundColor(.elevateTextGray)
                            }

                            Spacer()

                            Button(action: {
                                router.currentScreen = .addMember
                                router.selectedTab = .profile
                            }) {
                                HStack(spacing: 6) {
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
                            .accessibilityLabel("Add new member")
                        }
                        .padding(.horizontal, 24)

                        VStack(spacing: 12) {
                            ForEach(filteredMembers) { member in
                                memberRow(member)
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
        .sheet(item: $editingMember) { member in
            MemberEditorView(member: member, onSave: { draft in
                viewModel.updateMember(
                    member,
                    displayName: draft.displayName,
                    role: draft.role,
                    email: draft.email,
                    phone: draft.phone,
                    profileImage: draft.profileImage,
                    isOnline: NetworkService.shared.isOnline
                )
            }, onDelete: {
                viewModel.deleteMember(member, isOnline: NetworkService.shared.isOnline) { success in
                    if success {
                        // deleted successfully
                    }
                }
            })
        }
    }

    private var searchBar: some View {
        CustomSearchBar(text: $searchText, placeholder: "Search members...")
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 24)
    }

    private func memberRow(_ member: User) -> some View {
        let name = member.displayName.isEmpty ? member.username : member.displayName
        let role = member.role.isEmpty ? "Member" : member.role.capitalized

        return HStack(spacing: 12) {
            // Avatar — shows uploaded profile photo if available
            ProfilePhotoView(userId: member.id, size: 52)
                .overlay(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color.elevateDarkGreen)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        .offset(x: 2, y: 2)
                }

            // Name + Role
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .scaledFont(size: 14, weight: .bold)
                    .foregroundColor(.black)
                HStack(spacing: 5) {
                    Image(systemName: "briefcase.circle")
                        .font(.system(size: 11))
                        .foregroundColor(.elevateTextGray)
                    Text(role)
                        .scaledFont(size: 11, weight: .medium)
                        .foregroundColor(.elevateTextGray)
                }
            }

            Spacer()

            // ID Badge
            Text(shortId(member.id))
                .scaledFont(size: 11, weight: .bold)
                .foregroundColor(.elevateDarkGreen)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .frame(minWidth: 52)
                .background(Color.elevateDarkGreen.opacity(0.08))
                .cornerRadius(8)
                .accessibilityLabel("User ID \(shortId(member.id))")

            // Edit Button — standalone, not nested in a nav button
            Button(action: {
                editingMember = member
            }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.elevateDarkGreen)
                    .frame(width: 34, height: 34)
                    .background(Color.elevateDarkGreen.opacity(0.08))
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit \(name)")
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)
        // Row tap → member details (using onTapGesture avoids nested-button conflict)
        .contentShape(Rectangle())
        .onTapGesture {
            router.selectedMemberId = member.id
            router.currentScreen = .memberDetails
            router.selectedTab = .profile
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(name), \(role)")
    }

    private func shortId(_ id: String) -> String {
        String(id.prefix(6)).uppercased()
    }
}

#Preview {
    ManagerMembersView()
        .environmentObject(AppSession())
}
