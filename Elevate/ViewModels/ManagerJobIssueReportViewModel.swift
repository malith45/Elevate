import Foundation
import Combine

final class ManagerJobIssueReportViewModel: ObservableObject {
    @Published var job: Job?
    @Published var report: IssueReport?
    @Published var technician: User?

    private let localStorage = LocalStorageService.shared

    func load(jobId: String) {
        job = localStorage.fetchJob(id: jobId)
        if let report = localStorage.fetchIssueReports(jobId: jobId).first {
            self.report = report
            technician = localStorage.fetchUser(id: report.userId)
        } else if let job = job {
            technician = localStorage.fetchUser(id: job.assignedUserId)
        }
    }
}
