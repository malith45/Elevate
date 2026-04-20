import SwiftUI

struct ManagerMembersView: View {
    @Environment(\.managerTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = ManagerMembersViewModel()
    @ObservedObject var settings = AccessibilitySettings.shared
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
            settings.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                BackHeaderNav(isManager: true, onBack: {
                    router.currentScreen = .organization
                    router.selectedTab = .profile
                })
                .background(settings.surfaceColor)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Team Members")
                                .scaledFont(size: 28, weight: .bold, design: .rounded)
                                .foregroundColor(settings.primaryText)
                            Text("Manage and coordinate your active personnel.")
                                .scaledFont(size: 14)
                                .foregroundColor(settings.secondaryText)
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
                                    .background(settings.isHighContrast ? Color.black : Color.elevateDarkGreen)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 1)
                                    )
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
                        .stroke(settings.cardStroke, lineWidth: settings.isHighContrast ? 2 : 1)
                )

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .scaledFont(size: 15, weight: .bold)
                    .foregroundColor(settings.primaryText)
                
                HStack(spacing: 4) {
                    Image(systemName: member.role.uppercased() == "MANAGER" ? "person.badge.shield.fill" : "hammer.fill")
                        .font(.system(size: 9))
                        .foregroundColor(settings.accentColor)
                    
                    Text(role)
                        .scaledFont(size: 11, weight: .semibold)
                        .foregroundColor(settings.secondaryText)
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
                        .foregroundColor(settings.isHighContrast ? .white : settings.accentColor)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(settings.isHighContrast ? Color.black : settings.accentColor.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(settings.secondaryText.opacity(0.5))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(settings.surfaceColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
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
