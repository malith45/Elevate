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
                            if viewModel.reports.count > 1 {
                                reportPicker
                            }

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
                                    viewModel.sendResponse(text: responseText)
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
                                    viewModel.markResolved(responseText: responseText)
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
        .onChange(of: viewModel.report?.managerResponse) { _, newValue in
            if let newValue = newValue, responseText.isEmpty {
                responseText = newValue
            }
        }
        .alert("Issue Report", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var reportPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("REPORT HISTORY")
                .scaledFont(size: 10, weight: .bold)
                .foregroundColor(.elevateTextGray)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.reports) { report in
                        let isSelected = report.id == viewModel.report?.id
                        Button(action: {
                            viewModel.selectReport(report)
                            responseText = report.managerResponse ?? ""
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(report.priority)
                                    .scaledFont(size: 9, weight: .bold)
                                Text(shortDate(report.createdAt))
                                    .scaledFont(size: 10, weight: .bold)
                            }
                            .foregroundColor(isSelected ? .white : .elevateDarkGreen)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.elevateDarkGreen : Color.elevateLightGray)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
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

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    ManagerJobIssueReportView(jobId: "sample")
}
