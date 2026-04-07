import SwiftUI

struct ManagerJobIssueReportView: View {
    let jobId: String

    @Environment(\.managerTabRouter) private var router
    @StateObject private var viewModel = ManagerJobIssueReportViewModel()
    @State private var responseText = ""

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                BackHeaderNav(isManager: true, onBack: {
                    router.currentScreen = .jobDetails
                    router.selectedTab = .jobs
                })

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Issue Report")
                            .scaledFont(size: 28, weight: .bold, design: .rounded)
                            .foregroundColor(.elevateDarkGreen)

                        if let report = viewModel.report {
                            technicianCard

                            VStack(alignment: .leading, spacing: 8) {
                                Text("REPORT DESCRIPTION")
                                    .scaledFont(size: 10, weight: .bold)
                                    .foregroundColor(.elevateTextGray)
                                Text(report.description)
                                    .scaledFont(size: 14)
                                    .foregroundColor(.black.opacity(0.8))
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)

                            HStack(spacing: 12) {
                                Text("PRIORITY")
                                    .scaledFont(size: 10, weight: .bold)
                                    .foregroundColor(.elevateTextGray)
                                priorityPill(report.priority)
                            }

                            if !report.attachmentUrls.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("TECHNICIAN PHOTOS")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(.elevateTextGray)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(report.attachmentUrls, id: \.self) { url in
                                                PhotoPreview(urlString: url)
                                                    .frame(width: 80, height: 80)
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                Text("RESPONSE")
                                    .scaledFont(size: 10, weight: .bold)
                                    .foregroundColor(.elevateTextGray)

                                TextEditor(text: $responseText)
                                    .frame(height: 140)
                                    .padding(8)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.elevateLightGray, lineWidth: 1)
                                    )
                            }

                            HStack(spacing: 12) {
                                Button(action: {
                                    // TODO: Send response.
                                }) {
                                    Text("Send")
                                        .scaledFont(size: 14, weight: .bold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.elevateDarkGreen)
                                        .cornerRadius(12)
                                }

                                Button(action: {
                                    // TODO: Mark report resolved.
                                }) {
                                    Text("Mark Resolved")
                                        .scaledFont(size: 14, weight: .bold)
                                        .foregroundColor(.elevateDarkGreen)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.elevateLightGray)
                                        .cornerRadius(12)
                                }
                            }
                        } else {
                            Text("No issue reports found for this job.")
                                .scaledFont(size: 14)
                                .foregroundColor(.elevateTextGray)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { viewModel.load(jobId: jobId) }
    }

    private var technicianCard: some View {
        let name = viewModel.technician?.displayName.isEmpty == false ? viewModel.technician?.displayName : viewModel.technician?.username
        let displayName = name ?? "Assigned Technician"
        let memberId = viewModel.report?.userId ?? viewModel.job?.assignedUserId ?? "TECH-0000"

        return HStack(spacing: 16) {
            Circle()
                .fill(Color.elevateDarkGreen)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(displayName)
                    .scaledFont(size: 16, weight: .bold)
                Text("Member ID: \(memberId)")
                    .scaledFont(size: 12)
                    .foregroundColor(.elevateTextGray)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)
    }

    private func priorityPill(_ priority: String) -> some View {
        Text(priority)
            .scaledFont(size: 10, weight: .bold)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(priority == "HIGH" ? Color.red.opacity(0.15) : Color.elevateLightGray)
            .foregroundColor(priority == "HIGH" ? .red : .elevateDarkGreen)
            .cornerRadius(10)
    }
}

#Preview {
    ManagerJobIssueReportView(jobId: "sample")
}
