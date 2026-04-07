import SwiftUI

struct ManagerMembersView: View {
    @Environment(\.managerTabRouter) private var router

    private let members: [MemberItem] = [
        MemberItem(name: "Marcus V.", role: "3 Jobs Assigned", badge: "TECH-4092", isActive: true),
        MemberItem(name: "Elena R.", role: "1 Job Assigned", badge: "TECH-1102", isActive: true),
        MemberItem(name: "James D.", role: "Off Duty", badge: "TECH-8821", isActive: false),
        MemberItem(name: "Sarah K.", role: "5 Jobs Assigned", badge: "TECH-3029", isActive: true)
    ]

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
                                Text("12 Active")
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
                            ForEach(members) { member in
                                memberRow(member)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 12)
                }
            }
        }
        .navigationBarHidden(true)
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

    private func memberRow(_ member: MemberItem) -> some View {
        HStack(spacing: 12) {
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
                    .fill(member.isActive ? Color.elevateDarkGreen : Color.elevateTextGray)
                    .frame(width: 10, height: 10)
                    .offset(x: 2, y: 2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .scaledFont(size: 14, weight: .bold)
                    .foregroundColor(.black)
                HStack(spacing: 6) {
                    Image(systemName: member.isActive ? "briefcase" : "minus.circle")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.elevateTextGray)
                    Text(member.role)
                        .scaledFont(size: 10, weight: .medium)
                        .foregroundColor(.elevateTextGray)
                }
            }

            Spacer()

            Text(member.badge)
                .scaledFont(size: 9, weight: .bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.elevateLightGray)
                .cornerRadius(6)
                .foregroundColor(.elevateTextGray)

            Button(action: {
                // TODO: Edit member flow.
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
}

private struct MemberItem: Identifiable {
    let id = UUID()
    let name: String
    let role: String
    let badge: String
    let isActive: Bool
}

#Preview {
    ManagerMembersView()
}
