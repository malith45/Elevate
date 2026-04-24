import Foundation
import Combine

final class JobIssueReportViewModel: ObservableObject {
    @Published var issueText = ""
    @Published var priority = "MEDIUM"
    @Published var errorMessage: String?
    @Published var attachmentUrls: [String] = []
    @Published var didSubmit = false
    @Published var reports: [IssueReport] = []
    @Published var selectedReport: IssueReport?
    @Published var isNewReport = true

    private let localStorage = LocalStorageService.shared
    private let firebase = FirebaseService.shared
    private let network = NetworkService.shared

    func load(jobId: String) {
        reports = localStorage.fetchIssueReports(jobId: jobId)
        selectedReport = nil
        isNewReport = true
        
        guard network.isOnline else { return }
        
        firebase.fetchIssueReports(jobId: jobId) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if case .success(let remoteReports) = result {
                    // Update local storage
                    remoteReports.forEach { self.localStorage.saveIssueReport($0, isSynced: true) }
                    self.reports = remoteReports.sorted { $0.createdAt > $1.createdAt }
                }
            }
        }
    }

    func selectReport(_ report: IssueReport?) {
        if let report = report {
            selectedReport = report
            issueText = report.description
            priority = report.priority
            attachmentUrls = report.attachmentUrls
            isNewReport = false
        } else {
            selectedReport = nil
            issueText = ""
            priority = "MEDIUM"
            attachmentUrls = []
            isNewReport = true
        }
    }

    func addAttachment(data: Data) {
        if let base64String = ImageUtils.compressAndEncode(data: data) {
            attachmentUrls.append(base64String)
        }
    }

    func removeAttachment(url: String) {
        if let index = attachmentUrls.firstIndex(of: url) {
            attachmentUrls.remove(at: index)
        }
    }

    func submit(jobId: String, user: User, isOnline: Bool) {
        errorMessage = nil
        didSubmit = false

        guard !issueText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a description."
            return
        }

        let report = IssueReport(
            id: UUID().uuidString,
            jobId: jobId,
            userId: user.id,
            organizationId: user.organizationId,
            description: issueText,
            priority: priority,
            createdAt: Date(),
            attachmentUrls: attachmentUrls,
            managerResponse: nil,
            resolvedAt: nil
        )

        if isOnline {
            submitOnline(report)
        } else {
            localStorage.saveIssueReport(report, isSynced: false)
            didSubmit = true
        }
    }

    private func submitOnline(_ report: IssueReport) {
        firebase.createIssueReport(report) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if case .failure(let error) = result {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.localStorage.saveIssueReport(report, isSynced: true)
                    self.didSubmit = true
                    
                    // Notify managers of new issue report
                    NotificationManager.shared.notifyManagers(
                        organizationId: report.organizationId,
                        type: .issueReported,
                        title: "New Issue Reported",
                        body: "Technician reported an issue for a job. Priority: \(report.priority)",
                        targetId: report.jobId
                    )
                }
            }
        }
    }

}
