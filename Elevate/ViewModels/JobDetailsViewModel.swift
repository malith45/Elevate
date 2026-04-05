import Foundation
import Combine

final class JobDetailsViewModel: ObservableObject {
    @Published var job: Job?

    private let localStorage = LocalStorageService.shared
    private let firebase = FirebaseService.shared

    func load(jobId: String) {
        job = localStorage.fetchJob(id: jobId)
    }

    func updateStatus(jobId: String, status: String, user: User, isOnline: Bool) {
        let updatedAt = Date()
        localStorage.updateJobStatus(id: jobId, status: status, updatedAt: updatedAt)
        job = localStorage.fetchJob(id: jobId)

        if isOnline {
            firebase.updateJobStatus(jobId: jobId, status: status, updatedAt: updatedAt) { _ in }
        } else {
            SyncManager.shared.enqueueJobStatusUpdate(
                jobId: jobId,
                status: status,
                organizationId: user.organizationId,
                userId: user.id,
                updatedAt: updatedAt
            )
        }
    }

    func addPhoto(jobId: String, data: Data, isOnline: Bool) {
        let fileName = "job_\(jobId)_\(UUID().uuidString).jpg"
        if let localUrl = localStorage.saveImageData(data, fileName: fileName) {
            localStorage.appendJobPhotoUrl(jobId: jobId, url: localUrl)
            job = localStorage.fetchJob(id: jobId)

            if isOnline {
                firebase.uploadJobPhoto(data: data, fileName: fileName, jobId: jobId) { result in
                    if case .success(let remoteUrl) = result {
                        self.localStorage.replaceJobPhotoUrl(jobId: jobId, from: localUrl, to: remoteUrl)
                        DispatchQueue.main.async {
                            self.job = self.localStorage.fetchJob(id: jobId)
                        }
                    }
                }
            }
        }
    }
}
