import Foundation
import Combine

final class ManagerJobIssueReportViewModel: ObservableObject {
    @Published var job: Job?
    @Published var report: IssueReport?
    @Published var reports: [IssueReport] = []
    @Published var technician: User?
    @Published var errorMessage: String?

    private let localStorage = LocalStorageService.shared
    private let firebase = FirebaseService.shared
    private let network = NetworkService.shared

    func load(jobId: String) {
        job = localStorage.fetchJob(id: jobId)
        reports = localStorage.fetchIssueReports(jobId: jobId)
        report = reports.first

        if let selected = report {
            technician = localStorage.fetchUser(id: selected.userId)
        } else if let job = job {
            technician = localStorage.fetchUser(id: job.assignedUserId)
        }

        guard network.isOnline else { return }
        firebase.fetchIssueReports(jobId: jobId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let reports):
                    reports.forEach { self.localStorage.saveIssueReport($0, isSynced: true) }
                    self.reports = reports
                    self.report = reports.first
                    if let selected = self.report {
                        self.technician = self.localStorage.fetchUser(id: selected.userId)
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func selectReport(_ report: IssueReport) {
        self.report = report
        technician = localStorage.fetchUser(id: report.userId)
    }

    func sendResponse(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Enter a response before sending."
            return
        }
        guard let report = report else { return }
        guard network.isOnline else {
            errorMessage = "You are offline. Try again when connected."
            return
        }

        firebase.updateIssueReportResponse(reportId: report.id, response: trimmed, resolvedAt: report.resolvedAt) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    let updated = IssueReport(
                        id: report.id,
                        jobId: report.jobId,
                        userId: report.userId,
                        organizationId: report.organizationId,
                        description: report.description,
                        priority: report.priority,
                        createdAt: report.createdAt,
                        attachmentUrls: report.attachmentUrls,
                        managerResponse: trimmed,
                        resolvedAt: report.resolvedAt
                    )
                    self.localStorage.saveIssueReport(updated, isSynced: true)
                    self.report = updated
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func markResolved(responseText: String) {
        guard let report = report else { return }
        guard network.isOnline else {
            errorMessage = "You are offline. Try again when connected."
            return
        }

        let resolvedAt = Date()
        let response = responseText.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalResponse = response.isEmpty ? (report.managerResponse ?? "") : response

        firebase.updateIssueReportResponse(reportId: report.id, response: finalResponse, resolvedAt: resolvedAt) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    let updated = IssueReport(
                        id: report.id,
                        jobId: report.jobId,
                        userId: report.userId,
                        organizationId: report.organizationId,
                        description: report.description,
                        priority: report.priority,
                        createdAt: report.createdAt,
                        attachmentUrls: report.attachmentUrls,
                        managerResponse: finalResponse.isEmpty ? nil : finalResponse,
                        resolvedAt: resolvedAt
                    )
                    self.localStorage.saveIssueReport(updated, isSynced: true)
                    self.report = updated
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
