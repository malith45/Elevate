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

    func addAttachment(data: Data, fileName: String) {
        if let url = localStorage.saveImageData(data, fileName: fileName) {
            attachmentUrls.append(url)
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
            attachmentUrls: attachmentUrls
        )

        if isOnline {
            submitOnline(report)
        } else {
            localStorage.saveIssueReport(report, isSynced: false)
            didSubmit = true
        }
    }

    private func submitOnline(_ report: IssueReport) {
        let localUrls = report.attachmentUrls.filter { $0.hasPrefix("file://") }
        if localUrls.isEmpty {
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
            return
        }

        var uploadedUrls: [String] = []
        let group = DispatchGroup()

        localUrls.forEach { localUrl in
            guard let data = loadFileData(localUrl) else { return }
            group.enter()
            let fileName = "issue_\(report.id)_\(UUID().uuidString).jpg"
            firebase.uploadIssueAttachment(data: data, fileName: fileName) { result in
                if case .success(let url) = result {
                    uploadedUrls.append(url)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let mergedUrls = report.attachmentUrls.filter { !$0.hasPrefix("file://") } + uploadedUrls
            let updated = IssueReport(
                id: report.id,
                jobId: report.jobId,
                userId: report.userId,
                organizationId: report.organizationId,
                description: report.description,
                priority: report.priority,
                createdAt: report.createdAt,
                attachmentUrls: mergedUrls
            )
            self.firebase.createIssueReport(updated) { [weak self] result in
                DispatchQueue.main.async {
                    if case .failure(let error) = result {
                        self?.errorMessage = error.localizedDescription
                    } else {
                        self?.localStorage.saveIssueReport(updated, isSynced: true)
                        self?.didSubmit = true
                    }
                }
            }
        }
    }

    private func loadFileData(_ path: String) -> Data? {
        guard let url = URL(string: path) else { return nil }
        return try? Data(contentsOf: url)
    }
}
