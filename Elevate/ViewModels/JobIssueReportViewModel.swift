import Foundation
import Combine

final class JobIssueReportViewModel: ObservableObject {
    @Published var issueText = ""
    @Published var priority = "MEDIUM"
    @Published var errorMessage: String?
    @Published var attachmentUrls: [String] = []
    @Published var didSubmit = false

    private let localStorage = LocalStorageService.shared
    private let firebase = FirebaseService.shared

    func addAttachment(data: Data) {
        if let base64String = ImageUtils.compressAndEncode(data: data) {
            attachmentUrls.append(base64String)
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
            DispatchQueue.main.async {
                if case .failure(let error) = result {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.localStorage.saveIssueReport(report, isSynced: true)
                    self?.didSubmit = true
                }
            }
        }
    }

}
