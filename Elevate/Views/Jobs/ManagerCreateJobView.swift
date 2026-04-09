import SwiftUI

struct ManagerCreateJobView: View {
    @Environment(\.managerTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = ManagerCreateJobViewModel()
    @ObservedObject private var network = NetworkService.shared
    @State private var selectedTechnicianId: String?
    @State private var jobTitle = ""
    @State private var location = ""
    @State private var scheduledAt = Date()
    @State private var descriptionText = ""
    @State private var isUrgent = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                BackHeaderNav(isManager: true, onBack: {
                    router.currentScreen = .jobs
                    router.selectedTab = .jobs
                })

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Create Job")
                            .scaledFont(size: 26, weight: .bold, design: .rounded)
                            .foregroundColor(.elevateDarkGreen)
                            .padding(.horizontal, 24)
                            .padding(.top, 12)

                        VStack(alignment: .leading, spacing: 16) {
                            labeledSection(title: "ASSIGN TECHNICIAN") {
                                Menu {
                                    Picker("Technician", selection: $selectedTechnicianId) {
                                        ForEach(viewModel.technicians, id: \.id) { tech in
                                            Text(displayName(for: tech)).tag(Optional(tech.id))
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedTechnicianLabel())
                                            .scaledFont(size: 14)
                                            .foregroundColor(selectedTechnicianId == nil ? .elevateTextGray : .black)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.elevateTextGray)
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.elevateLightGray, lineWidth: 1)
                                    )
                                }
                            }

                            labeledSection(title: "JOB TITLE") {
                                TextField("Enter job title", text: $jobTitle)
                                    .scaledFont(size: 14)
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.elevateLightGray, lineWidth: 1)
                                    )
                            }

                            labeledSection(title: "SET SITE") {
                                HStack {
                                    TextField("Enter project location", text: $location)
                                        .scaledFont(size: 14)
                                    Spacer()
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundColor(.elevateTextGray)
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.elevateLightGray, lineWidth: 1)
                                )
                            }

                            HStack(spacing: 16) {
                                labeledSection(title: "DATE") {
                                    DatePicker("", selection: $scheduledAt, displayedComponents: .date)
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(12)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.elevateLightGray, lineWidth: 1)
                                        )
                                }

                                labeledSection(title: "TIME") {
                                    DatePicker("", selection: $scheduledAt, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(12)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.elevateLightGray, lineWidth: 1)
                                        )
                                }
                            }

                            Toggle(isOn: $isUrgent) {
                                Text("Mark as urgent")
                                    .scaledFont(size: 12, weight: .bold)
                                    .foregroundColor(.elevateTextGray)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .elevateDarkGreen))

                            labeledSection(title: "DESCRIPTION") {
                                TextEditor(text: $descriptionText)
                                    .frame(height: 140)
                                    .padding(8)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.elevateLightGray, lineWidth: 1)
                                    )
                            }

                            labeledSection(title: "SITE PREVIEW") {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.elevateLightGray.opacity(0.6))
                                    .frame(height: 160)
                                    .overlay(
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(.elevateDarkGreen.opacity(0.5))
                                    )
                            }
                        }
                        .padding(.horizontal, 24)

                        PrimaryButton(title: "Create Job", iconName: "checkmark") {
                            createJob()
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
            viewModel.loadTechnicians(organizationId: user.organizationId, isOnline: network.isOnline)
        }
        .alert("Create Job", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func labeledSection<Content: View>(title: String, content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .scaledFont(size: 10, weight: .bold)
                .foregroundColor(.elevateTextGray)
            content()
        }
    }

    private func displayName(for user: User) -> String {
        user.displayName.isEmpty ? user.username : user.displayName
    }

    private func selectedTechnicianLabel() -> String {
        guard let selectedId = selectedTechnicianId,
              let tech = viewModel.technicians.first(where: { $0.id == selectedId })
        else { return "Select Technician" }
        return displayName(for: tech)
    }

    private func createJob() {
        guard let user = appSession.currentUser else { return }
        let assignedId = selectedTechnicianId ?? ""
        viewModel.createJob(
            organizationId: user.organizationId,
            assignedUserId: assignedId,
            title: jobTitle,
            location: location,
            scheduledAt: scheduledAt,
            notes: descriptionText,
            isUrgent: isUrgent,
            isOnline: network.isOnline
        ) { job in
            if job != nil {
                router.currentScreen = .jobs
                router.selectedTab = .jobs
            }
        }
    }
}

#Preview {
    ManagerCreateJobView()
        .environmentObject(AppSession())
}
