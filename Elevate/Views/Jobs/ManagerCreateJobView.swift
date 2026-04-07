import SwiftUI

struct ManagerCreateJobView: View {
    @Environment(\.managerTabRouter) private var router
    @State private var selectedTechnician = "Select Technician"
    @State private var location = ""
    @State private var dateText = ""
    @State private var timeText = ""
    @State private var descriptionText = ""

    private let technicians = ["Select Technician", "Marcus V.", "Elena R.", "James D."]

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
                                    Picker("Technician", selection: $selectedTechnician) {
                                        ForEach(technicians, id: \.self) { tech in
                                            Text(tech).tag(tech)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedTechnician)
                                            .scaledFont(size: 14)
                                            .foregroundColor(selectedTechnician == "Select Technician" ? .elevateTextGray : .black)
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
                                    TextField("mm/dd/yyyy", text: $dateText)
                                        .scaledFont(size: 14)
                                        .padding(12)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.elevateLightGray, lineWidth: 1)
                                        )
                                }

                                labeledSection(title: "TIME") {
                                    TextField("--:--", text: $timeText)
                                        .scaledFont(size: 14)
                                        .padding(12)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.elevateLightGray, lineWidth: 1)
                                        )
                                }
                            }

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
                            // TODO: Save job.
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func labeledSection<Content: View>(title: String, content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .scaledFont(size: 10, weight: .bold)
                .foregroundColor(.elevateTextGray)
            content()
        }
    }
}

#Preview {
    ManagerCreateJobView()
}
