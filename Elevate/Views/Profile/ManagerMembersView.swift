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
            $0.displayName.localizedCaseInsensitiveContains(searchText)
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
                    VStack(alignment: .leading, spacing: 28) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Team Members")
                                .scaledFont(size: 28, weight: .bold, design: .rounded)
                            Text("Manage and coordinate your active personnel.")
                                .scaledFont(size: 14)
                                .foregroundColor(.elevateTextGray)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                CustomSearchBar(text: $searchText, placeholder: "Search by display name...")
                                
                                Button(action: {
                                    router.currentScreen = .addMember
                                    router.selectedTab = .profile
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 14))
                                        Text("Add")
                                            .scaledFont(size: 12, weight: .bold)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.elevateDarkGreen)
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 24)

                            if filteredMembers.isEmpty {
                                EmptyStateView(title: "No Members Found", message: "Try a different search term or add a new team member.")
                                    .padding(.top, 40)
                            } else {
                                VStack(spacing: 14) {
                                    ForEach(filteredMembers) { member in
                                        memberRow(member)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        // Bottom buffer for smooth scrolling
                        Color.clear.frame(height: 20)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            guard let user = appSession.currentUser else { return }
            viewModel.load(organizationId: user.organizationId, isOnline: NetworkService.shared.isOnline)
        }
        .sheet(item: $editingMember) { member in
            MemberEditorView(member: member, onSave: { draft in
                viewModel.updateMember(
                    member,
                    displayName: draft.displayName,
                    role: draft.role,
                    email: draft.email,
                    phone: draft.phone,
                    password: draft.password,
                    profileImage: draft.profileImage,
                    isOnline: NetworkService.shared.isOnline
                )
            }, onDelete: {
                viewModel.deleteMember(member, isOnline: NetworkService.shared.isOnline) { _ in }
            })
        }
    }

    private func memberRow(_ member: User) -> some View {
        let name = member.displayName.isEmpty ? member.username : member.displayName
        let role = member.role.capitalized

        return HStack(spacing: 12) {
            // Avatar
            ProfilePhotoView(userId: member.id, size: 54)
                .overlay(
                    Circle()
                        .stroke(Color.elevateLightGray.opacity(0.5), lineWidth: 1)
                )

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .scaledFont(size: 15, weight: .bold)
                    .foregroundColor(.black)
                
                HStack(spacing: 4) {
                    Image(systemName: member.role.uppercased() == "MANAGER" ? "person.badge.shield.fill" : "hammer.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.elevateDarkGreen)
                    
                    Text(role)
                        .scaledFont(size: 11, weight: .semibold)
                        .foregroundColor(.elevateTextGray)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 10) {
                Button(action: {
                    editingMember = member
                }) {
                    Text("Edit")
                        .scaledFont(size: 11, weight: .bold)
                        .foregroundColor(.elevateDarkGreen)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.elevateDarkGreen.opacity(0.1))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.elevateLightGray.opacity(0.5))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.01), radius: 5, x: 0, y: 2)
        .onTapGesture {
            HapticManager.shared.playNotification(type: .success)
            router.selectedMemberId = member.id
            router.currentScreen = .memberDetails
            router.selectedTab = .profile
        }
    }
}

#Preview {
    ManagerMembersView()
        .environmentObject(AppSession())
}
