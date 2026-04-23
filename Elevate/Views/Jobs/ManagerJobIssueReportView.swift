import SwiftUI

struct ManagerJobIssueReportView: View {
    let jobId: String

    @Environment(\.managerTabRouter) private var router
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ManagerJobIssueReportViewModel()
    @ObservedObject var settings = AccessibilitySettings.shared
    @State private var responseText = ""
    @State private var jobStatus: String = "PENDING"
    
    private var isTerminal: Bool {
        let status = jobStatus.uppercased()
        return status == "COMPLETED" || status == "CANCELLED"
    }

    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                BackHeaderNav(isManager: true, onBack: { dismiss() })

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        
                        if let report = viewModel.report {
                            if viewModel.reports.count > 1 { reportPicker }
                            technicianCard
                            reportDetailsCard(report)
                            if !report.attachmentUrls.isEmpty { photoGridCard(report) }
                            managerResponseCard
                            if !isTerminal {
                                actionButtons
                            }
                        } else {
                            emptyStateView
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { 
            viewModel.load(jobId: jobId)
            if let job = LocalStorageService.shared.fetchJob(id: jobId) {
                jobStatus = job.status
            }
        }
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

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Issue Report")
                .scaledFont(size: 28, weight: .bold, design: .rounded)
                .foregroundColor(settings.primaryText)
            Text("Review and respond to technical site failures")
                .scaledFont(size: 15, weight: .medium)
                .foregroundColor(settings.secondaryText)
        }
        .padding(.top, 20)
    }

    private func reportDetailsCard(_ report: IssueReport) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "text.bubble.fill")
                    .foregroundColor(settings.accentColor)
                Text("REPORT DESCRIPTION")
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundColor(settings.secondaryText)
                    .tracking(1)
                Spacer()
                priorityPill(report.priority)
            }

            Text(report.description)
                .scaledFont(size: 15)
                .foregroundColor(settings.primaryText.opacity(0.9))
                .lineSpacing(4)
        }
        .padding(20)
        .background(settings.surfaceColor)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }

    private func photoGridCard(_ report: IssueReport) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "camera.fill")
                    .foregroundColor(settings.accentColor)
                Text("TECHNICIAN PHOTOS")
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundColor(settings.secondaryText)
                    .tracking(1)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(report.attachmentUrls, id: \.self) { url in
                        PhotoPreview(urlString: url)
                            .frame(width: 90, height: 90)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                            )
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(20)
        .background(settings.surfaceColor)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }

    private var managerResponseCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrowshape.turn.up.left.fill")
                    .foregroundColor(settings.accentColor)
                Text("MANAGER RESPONSE")
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundColor(settings.secondaryText)
                    .tracking(1)
            }

            ZStack(alignment: .topLeading) {
                if responseText.isEmpty {
                    Text("Enter your instructions or response here...")
                        .scaledFont(size: 15)
                        .foregroundColor(settings.secondaryText.opacity(0.6))
                        .padding(.top, 12)
                        .padding(.leading, 12)
                }
                TextEditor(text: $responseText)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .background(settings.surfaceColor)
                    .foregroundColor(settings.primaryText)
                    .scaledFont(size: 15)
                    .disabled(isTerminal)
            }
            .padding(12)
            .background(settings.surfaceColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
            )
        }
        .padding(20)
        .background(settings.surfaceColor)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                HapticManager.shared.playImpact(style: .medium)
                viewModel.sendResponse(text: responseText)
            }) {
                HStack {
                    Text("UPDATE RESPONSE")
                    Spacer()
                    Image(systemName: "paperplane.fill")
                }
                .scaledFont(size: 15, weight: .bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .padding(.horizontal, 24)
                .background(settings.isHighContrast ? settings.surfaceColor : Color.elevateDarkGreen)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                )
            }

            Button(action: {
                HapticManager.shared.playImpact(style: .heavy)
                viewModel.markResolved(responseText: responseText)
            }) {
                HStack {
                    Text("MARK AS RESOLVED")
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                }
                .scaledFont(size: 15, weight: .bold)
                .foregroundColor(settings.accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .padding(.horizontal, 24)
                .background(settings.isHighContrast ? settings.surfaceColor : settings.accentColor.opacity(0.1))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(settings.accentColor.opacity(0.3), lineWidth: settings.cardStrokeWidth)
                )
            }
        }
        .padding(.top, 8)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(settings.secondaryText.opacity(0.3))
            Text("No issue reports found for this job.")
                .scaledFont(size: 16, weight: .medium)
                .foregroundColor(settings.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var reportPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(settings.accentColor)
                Text("REPORT HISTORY")
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundColor(settings.secondaryText)
                    .tracking(1)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.reports) { report in
                        let isSelected = report.id == viewModel.report?.id
                        Button(action: {
                            HapticManager.shared.playImpact(style: .light)
                            viewModel.selectReport(report)
                            responseText = report.managerResponse ?? ""
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(report.priority)
                                    .scaledFont(size: 9, weight: .bold)
                                Text(shortDate(report.createdAt))
                                    .scaledFont(size: 10, weight: .bold)
                            }
                            .foregroundColor(isSelected ? .white : settings.primaryText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(isSelected ? (settings.isHighContrast ? settings.surfaceColor : settings.accentColor) : settings.surfaceColor)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected && settings.isHighContrast ? settings.primaryText : settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(20)
        .background(settings.surfaceColor)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }

    private var technicianCard: some View {
        let name = viewModel.technician?.displayName.isEmpty == false ? viewModel.technician?.displayName : viewModel.technician?.username
        let displayName = name ?? "Assigned Technician"
        let memberId = viewModel.report?.userId ?? viewModel.job?.assignedUserId ?? "TECH-0000"
        let shortId = String(memberId.prefix(6))

        return HStack(spacing: 16) {
            Circle()
                .fill(settings.accentColor.opacity(0.1))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(settings.accentColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .scaledFont(size: 16, weight: .bold)
                    .foregroundColor(settings.primaryText)
                Text("Technician ID: \(shortId)")
                    .scaledFont(size: 12, weight: .medium)
                    .foregroundColor(settings.secondaryText)
            }

            Spacer()
        }
        .padding(20)
        .background(settings.surfaceColor)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }

    private func priorityPill(_ priority: String) -> some View {
        Text(priority)
            .scaledFont(size: 10, weight: .bold)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(settings.isHighContrast ? settings.surfaceColor : (priority == "HIGH" ? Color.red.opacity(0.1) : settings.accentColor.opacity(0.1)))
            .foregroundColor(settings.isHighContrast ? settings.primaryText : (priority == "HIGH" ? .red : settings.accentColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(settings.isHighContrast ? settings.primaryText : (priority == "HIGH" ? Color.red.opacity(0.2) : settings.accentColor.opacity(0.2)), lineWidth: 1)
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
