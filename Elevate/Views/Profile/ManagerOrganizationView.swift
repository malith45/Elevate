import SwiftUI

struct ManagerOrganizationView: View {
    @Environment(\.managerTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @State private var organizationNameDraft = ""
    @State private var introductionDraft = ""
    @State private var isEditingName = false
    @State private var isEditingIntroduction = false

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
                                metricCard(title: "ACTIVE MEMBERS", value: "24", icon: "person.2")
                                metricCard(title: "MANAGEMENT", value: "3", icon: "person.3")
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
            }
        }
        .navigationBarHidden(true)
        .alert("Edit Organization Name", isPresented: $isEditingName) {
            TextField("Organization Name", text: $organizationNameDraft)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                // TODO: Persist organization name update.
            }
        }
        .alert("Edit Introduction", isPresented: $isEditingIntroduction) {
            TextField("Introduction", text: $introductionDraft)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                // TODO: Persist introduction update.
            }
        }
    }

    private var organizationName: String {
        if let user = appSession.currentUser {
            return user.organizationId
        }
        return "Skyline Corp"
    }

    private var introductionText: String {
        "Manage your organization profile, members, and permissions from this hub."
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
}

#Preview {
    ManagerOrganizationView()
        .environmentObject(AppSession())
}
