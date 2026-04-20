import SwiftUI

struct ManagerJobIssueReportView: View {
    let jobId: String

    @Environment(\.managerTabRouter) private var router
    @StateObject private var viewModel = ManagerJobIssueReportViewModel()
    @ObservedObject var settings = AccessibilitySettings.shared
    @State private var responseText = ""

    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                BackHeaderNav(isManager: true, onBack: {
                    router.currentScreen = .jobDetails
                    router.selectedTab = .jobs
                })

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Issue Report")
                            .scaledFont(size: 28, weight: .bold, design: .rounded)
                            .foregroundColor(settings.accentColor)

                        if let report = viewModel.report {
                            if viewModel.reports.count > 1 {
                                reportPicker
                            }

                            technicianCard

                            VStack(alignment: .leading, spacing: 8) {
                                Text("REPORT DESCRIPTION")
                                    .scaledFont(size: 10, weight: .bold)
                                    .foregroundColor(settings.secondaryText)
                                Text(report.description)
                                    .scaledFont(size: 14)
                                    .foregroundColor(settings.primaryText.opacity(0.8))
                            }
                            .padding(16)
                            .background(settings.surfaceColor)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)

                            HStack(spacing: 12) {
                                Text("PRIORITY")
                                    .scaledFont(size: 10, weight: .bold)
                                    .foregroundColor(settings.secondaryText)
                                priorityPill(report.priority)
                            }

                            if !report.attachmentUrls.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("TECHNICIAN PHOTOS")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(settings.secondaryText)

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
                                    .foregroundColor(settings.secondaryText)

                                TextEditor(text: $responseText)
                                    .frame(height: 140)
                                    .padding(8)
                                    .scrollContentBackground(.hidden)
                                    .background(settings.surfaceColor)
                                    .foregroundColor(settings.primaryText)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
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
                                        .background(settings.isHighContrast ? Color.black : Color.elevateDarkGreen)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 2)
                                        )
                                }

                                Button(action: {
                                    viewModel.markResolved(responseText: responseText)
                                }) {
                                    Text("Mark Resolved")
                                        .scaledFont(size: 14, weight: .bold)
                                        .foregroundColor(settings.isHighContrast ? .white : settings.accentColor)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(settings.isHighContrast ? Color.black : Color.elevateLightGray)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 1)
                                        )
                                }
                            }
                        } else {
                            Text("No issue reports found for this job.")
                                .scaledFont(size: 14)
                                .foregroundColor(settings.secondaryText)
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
                .foregroundColor(settings.secondaryText)

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
                            .foregroundColor(isSelected ? .white : settings.accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(isSelected ? (settings.isHighContrast ? Color.black : settings.accentColor) : (settings.isHighContrast ? Color.black : Color.elevateLightGray))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected && settings.isHighContrast ? Color.white : (settings.isHighContrast ? settings.cardStroke : Color.clear), lineWidth: 1)
                            )
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
        let shortId = String(memberId.prefix(6))

        return HStack(spacing: 16) {
            Circle()
                .fill(settings.isHighContrast ? Color.black : settings.accentColor)
                .frame(width: 56, height: 56)
                .overlay(
                    Circle().stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 2)
                )
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(displayName)
                    .scaledFont(size: 16, weight: .bold)
                    .foregroundColor(settings.primaryText)
                Text("Member ID: \(shortId)")
                    .scaledFont(size: 12)
                    .foregroundColor(settings.secondaryText)
            }

            Spacer()
        }
        .padding(16)
        .background(settings.surfaceColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)
    }

    private func priorityPill(_ priority: String) -> some View {
        Text(priority)
            .scaledFont(size: 10, weight: .bold)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(settings.isHighContrast ? Color.black : (priority == "HIGH" ? Color.red.opacity(0.15) : Color.elevateLightGray))
            .foregroundColor(settings.isHighContrast ? .white : (priority == "HIGH" ? .red : .elevateDarkGreen))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 1)
            )
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
