import Foundation
import Combine

final class SyncManager: ObservableObject {
    static let shared = SyncManager()

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case offline
        case upToDate
        case error(String)
    }

    @Published private(set) var status: SyncStatus = .idle
    @Published private(set) var pendingCount: Int = 0
    @Published private(set) var lastSyncAt: Date?

    private let network = NetworkService.shared
    private let firebase = FirebaseService.shared
    private let local = LocalStorageService.shared

    private init() {}

    func startSyncing(organizationId: String, userId: String, completion: (() -> Void)? = nil) {
        pendingCount = local.pendingActionsCount(organizationId: organizationId, userId: userId)

        guard network.isOnline else {
            status = .offline
            completion?()
            return
        }

        status = .syncing
        syncPendingActions(organizationId: organizationId, userId: userId) { [weak self] in
            self?.syncJobs(organizationId: organizationId) { [weak self] in
                self?.syncPendingJobPhotos(organizationId: organizationId)
                self?.syncPendingIssueReports()
                self?.pendingCount = self?.local.pendingActionsCount(organizationId: organizationId, userId: userId) ?? 0
                self?.lastSyncAt = Date()
                self?.status = (self?.pendingCount == 0) ? .upToDate : .syncing
                completion?()
            }
        }
    }

    func enqueueJobStatusUpdate(jobId: String, status: String, organizationId: String, userId: String, updatedAt: Date) {
        let payload: [String: Any] = [
            "jobId": jobId,
            "status": status,
            "updatedAt": updatedAt.timeIntervalSince1970
        ]
        if let data = encodePayload(payload) {
            let action = PendingAction(
                id: UUID().uuidString,
                organizationId: organizationId,
                userId: userId,
                type: .updateJobStatus,
                payload: data,
                createdAt: Date()
            )
            local.enqueuePendingAction(action)
            pendingCount = local.pendingActionsCount(organizationId: organizationId, userId: userId)
        }
    }

    func enqueueCreateJob(_ job: Job, organizationId: String, userId: String) {
        var payload = jobPayload(job)
        payload["organizationId"] = organizationId

        if let data = encodePayload(payload) {
            let action = PendingAction(
                id: UUID().uuidString,
                organizationId: organizationId,
                userId: userId,
                type: .createJob,
                payload: data,
                createdAt: Date()
            )
            local.enqueuePendingAction(action)
            pendingCount = local.pendingActionsCount(organizationId: organizationId, userId: userId)
        }
    }

    func enqueueJobFieldsUpdate(jobId: String, fields: [String: Any], organizationId: String, userId: String) {
        var payload: [String: Any] = [
            "jobId": jobId,
            "updatedAt": Date().timeIntervalSince1970
        ]

        if let status = fields["status"] as? String {
            payload["status"] = status
        }
        if let isOnHold = fields["isOnHold"] as? Bool {
            payload["isOnHold"] = isOnHold
        }
        if let holdReason = fields["holdReason"] as? String {
            payload["holdReason"] = holdReason
        }
        if let cancelledAt = fields["cancelledAt"] as? Date {
            payload["cancelledAt"] = cancelledAt.timeIntervalSince1970
        }

        if let data = encodePayload(payload) {
            let action = PendingAction(
                id: UUID().uuidString,
                organizationId: organizationId,
                userId: userId,
                type: .updateJobFields,
                payload: data,
                createdAt: Date()
            )
            local.enqueuePendingAction(action)
            pendingCount = local.pendingActionsCount(organizationId: organizationId, userId: userId)
        }
    }

    func enqueueQuotationRequest(jobId: String, userId: String, organizationId: String, items: [QuotationItem]) {
        let itemsPayload: [[String: Any]] = items.map {
            [
                "id": $0.id,
                "name": $0.name,
                "unitPrice": $0.unitPrice,
                "quantity": $0.quantity,
                "status": $0.status
            ]
        }

        let payload: [String: Any] = [
            "jobId": jobId,
            "userId": userId,
            "items": itemsPayload,
            "updatedAt": Date().timeIntervalSince1970
        ]

        if let data = encodePayload(payload) {
            let action = PendingAction(
                id: UUID().uuidString,
                organizationId: organizationId,
                userId: userId,
                type: .submitQuotationRequest,
                payload: data,
                createdAt: Date()
            )
            local.enqueuePendingAction(action)
            pendingCount = local.pendingActionsCount(organizationId: organizationId, userId: userId)
        }
    }

    func enqueueQuotationItemsUpdate(jobId: String, organizationId: String, userId: String, items: [QuotationItem], approvedCost: Double) {
        let itemsPayload: [[String: Any]] = items.map {
            [
                "id": $0.id,
                "name": $0.name,
                "unitPrice": $0.unitPrice,
                "quantity": $0.quantity,
                "status": $0.status
            ]
        }

        let payload: [String: Any] = [
            "jobId": jobId,
            "items": itemsPayload,
            "approvedCost": approvedCost,
            "updatedAt": Date().timeIntervalSince1970
        ]

        if let data = encodePayload(payload) {
            let action = PendingAction(
                id: UUID().uuidString,
                organizationId: organizationId,
                userId: userId,
                type: .updateQuotationItems,
                payload: data,
                createdAt: Date()
            )
            local.enqueuePendingAction(action)
            pendingCount = local.pendingActionsCount(organizationId: organizationId, userId: userId)
        }
    }

    func enqueueCreateInventoryItem(_ item: InventoryItem, organizationId: String, userId: String) {
        let payload: [String: Any] = [
            "id": item.id,
            "organizationId": item.organizationId,
            "name": item.name,
            "category": item.category,
            "quantity": item.quantity,
            "unitPrice": item.unitPrice,
            "sku": item.sku as Any,
            "imageUrl": item.imageUrl as Any
        ]

        if let data = encodePayload(payload) {
            let action = PendingAction(
                id: UUID().uuidString,
                organizationId: organizationId,
                userId: userId,
                type: .createInventoryItem,
                payload: data,
                createdAt: Date()
            )
            local.enqueuePendingAction(action)
            pendingCount = local.pendingActionsCount(organizationId: organizationId, userId: userId)
        }
    }

    func enqueueUpdateInventoryItem(itemId: String, fields: [String: Any], organizationId: String, userId: String) {
        var payload = fields
        payload["itemId"] = itemId

        if let data = encodePayload(payload) {
            let action = PendingAction(
                id: UUID().uuidString,
                organizationId: organizationId,
                userId: userId,
                type: .updateInventoryItem,
                payload: data,
                createdAt: Date()
            )
            local.enqueuePendingAction(action)
            pendingCount = local.pendingActionsCount(organizationId: organizationId, userId: userId)
        }
    }

    func enqueueDeleteInventoryItem(itemId: String, organizationId: String, userId: String) {
        let payload: [String: Any] = [
            "itemId": itemId
        ]

        if let data = encodePayload(payload) {
            let action = PendingAction(
                id: UUID().uuidString,
                organizationId: organizationId,
                userId: userId,
                type: .deleteInventoryItem,
                payload: data,
                createdAt: Date()
            )
            local.enqueuePendingAction(action)
            pendingCount = local.pendingActionsCount(organizationId: organizationId, userId: userId)
        }
    }

    func enqueueUserProfileUpdate(userId: String, organizationId: String, actorUserId: String, fields: [String: Any]) {
        var payload = fields
        payload["userId"] = userId

        if let data = encodePayload(payload) {
            let action = PendingAction(
                id: UUID().uuidString,
                organizationId: organizationId,
                userId: actorUserId,
                type: .updateUserProfile,
                payload: data,
                createdAt: Date()
            )
            local.enqueuePendingAction(action)
            pendingCount = local.pendingActionsCount(organizationId: organizationId, userId: actorUserId)
        }
    }

    func enqueueUserProfileDelete(userId: String, organizationId: String, actorUserId: String) {
        let payload: [String: Any] = ["userId": userId]

        if let data = encodePayload(payload) {
            let action = PendingAction(
                id: UUID().uuidString,
                organizationId: organizationId,
                userId: actorUserId,
                type: .deleteUserProfile,
                payload: data,
                createdAt: Date()
            )
            local.enqueuePendingAction(action)
            pendingCount = local.pendingActionsCount(organizationId: organizationId, userId: actorUserId)
        }
    }

    func enqueueNotificationRead(notificationId: String, isRead: Bool, organizationId: String, userId: String) {
        let payload: [String: Any] = [
            "notificationId": notificationId,
            "isRead": isRead
        ]

        if let data = encodePayload(payload) {
            let action = PendingAction(
                id: UUID().uuidString,
                organizationId: organizationId,
                userId: userId,
                type: .markNotificationRead,
                payload: data,
                createdAt: Date()
            )
            local.enqueuePendingAction(action)
            pendingCount = local.pendingActionsCount(organizationId: organizationId, userId: userId)
        }
    }

    func enqueueClearNotifications(organizationId: String, userId: String) {
        let payload: [String: Any] = ["organizationId": organizationId]

        if let data = encodePayload(payload) {
            let action = PendingAction(
                id: UUID().uuidString,
                organizationId: organizationId,
                userId: userId,
                type: .clearNotifications,
                payload: data,
                createdAt: Date()
            )
            local.enqueuePendingAction(action)
            pendingCount = local.pendingActionsCount(organizationId: organizationId, userId: userId)
        }
    }

    func syncNotifications(organizationId: String, userId: String, completion: (() -> Void)? = nil) {
        guard network.isOnline else {
            completion?()
            return
        }

        firebase.fetchNotifications(organizationId: organizationId, userId: userId) { result in
            switch result {
            case .success(let items):
                self.local.saveNotifications(items)
            case .failure:
                break
            }
            completion?()
        }
    }

    private func syncPendingActions(organizationId: String, userId: String, completion: (() -> Void)? = nil) {
        let actions = local.fetchPendingActions(organizationId: organizationId, userId: userId)
        guard !actions.isEmpty else {
            completion?()
            return
        }

        let group = DispatchGroup()

        actions.forEach { action in
            switch action.type {
            case .createJob:
                guard let payload = decodePayload(action.payload),
                      let job = jobFromPayload(payload)
                else { return }

                group.enter()
                firebase.createJob(job) { result in
                    if case .success = result {
                        self.local.deletePendingAction(id: action.id)
                    }
                    group.leave()
                }
            case .updateJobStatus:
                guard let payload = decodePayload(action.payload),
                      let jobId = payload["jobId"] as? String,
                      let status = payload["status"] as? String,
                      let updatedAtValue = payload["updatedAt"] as? TimeInterval
                else { return }

                let localUpdatedAt = Date(timeIntervalSince1970: updatedAtValue)
                group.enter()
                firebase.fetchJob(jobId: jobId) { result in
                    switch result {
                    case .success(let remoteJob):
                        if remoteJob.updatedAt > localUpdatedAt {
                            self.local.updateJobStatus(id: jobId, status: remoteJob.status, updatedAt: remoteJob.updatedAt)
                            self.local.deletePendingAction(id: action.id)
                            group.leave()
                        } else {
                            self.firebase.updateJobStatus(jobId: jobId, status: status, updatedAt: localUpdatedAt) { updateResult in
                                if case .success = updateResult {
                                    self.local.deletePendingAction(id: action.id)
                                }
                                group.leave()
                            }
                        }
                    case .failure:
                        group.leave()
                    }
                }
            case .submitQuotationRequest:
                guard let payload = decodePayload(action.payload),
                      let jobId = payload["jobId"] as? String,
                      let userId = payload["userId"] as? String,
                      let itemsData = payload["items"] as? [[String: Any]]
                else { return }

                let items: [QuotationItem] = itemsData.compactMap { item in
                    guard let id = item["id"] as? String,
                          let name = item["name"] as? String,
                          let unitPrice = item["unitPrice"] as? Double,
                          let quantity = item["quantity"] as? Int,
                          let status = item["status"] as? String
                    else { return nil }
                    return QuotationItem(id: id, name: name, unitPrice: unitPrice, quantity: quantity, status: status)
                }

                guard !items.isEmpty else { return }

                group.enter()
                firebase.submitQuotationRequest(jobId: jobId, userId: userId, items: items) { result in
                    if case .success = result {
                        self.local.deletePendingAction(id: action.id)
                    }
                    group.leave()
                }
            case .updateQuotationItems:
                guard let payload = decodePayload(action.payload),
                      let jobId = payload["jobId"] as? String,
                      let itemsData = payload["items"] as? [[String: Any]]
                else { return }

                let approvedCost = payload["approvedCost"] as? Double ?? 0
                let items: [QuotationItem] = itemsData.compactMap { item in
                    guard let id = item["id"] as? String,
                          let name = item["name"] as? String,
                          let unitPrice = item["unitPrice"] as? Double,
                          let quantity = item["quantity"] as? Int,
                          let status = item["status"] as? String
                    else { return nil }
                    return QuotationItem(id: id, name: name, unitPrice: unitPrice, quantity: quantity, status: status)
                }

                group.enter()
                firebase.updateQuotationItems(jobId: jobId, items: items, approvedCost: approvedCost) { result in
                    if case .success = result {
                        self.local.deletePendingAction(id: action.id)
                    }
                    group.leave()
                }
            case .updateJobFields:
                guard let payload = decodePayload(action.payload),
                      let jobId = payload["jobId"] as? String,
                      let updatedAtValue = payload["updatedAt"] as? TimeInterval
                else { return }

                var fields: [String: Any] = [:]
                if let status = payload["status"] as? String {
                    fields["status"] = status
                }
                if let isOnHold = payload["isOnHold"] as? Bool {
                    fields["isOnHold"] = isOnHold
                }
                if let holdReason = payload["holdReason"] as? String {
                    fields["holdReason"] = holdReason
                }
                if let cancelledAtValue = payload["cancelledAt"] as? TimeInterval {
                    fields["cancelledAt"] = Date(timeIntervalSince1970: cancelledAtValue)
                }

                let localUpdatedAt = Date(timeIntervalSince1970: updatedAtValue)
                group.enter()
                firebase.fetchJob(jobId: jobId) { result in
                    switch result {
                    case .success(let remoteJob):
                        if remoteJob.updatedAt > localUpdatedAt {
                            self.local.saveJobs([remoteJob])
                            self.local.deletePendingAction(id: action.id)
                            group.leave()
                        } else {
                            self.firebase.updateJobFields(jobId: jobId, fields: fields) { updateResult in
                                if case .success = updateResult {
                                    self.local.deletePendingAction(id: action.id)
                                }
                                group.leave()
                            }
                        }
                    case .failure:
                        group.leave()
                    }
                }
            case .createInventoryItem:
                guard let payload = decodePayload(action.payload),
                      let item = inventoryItemFromPayload(payload)
                else { return }

                group.enter()
                firebase.createInventoryItem(item) { result in
                    if case .success = result {
                        self.local.deletePendingAction(id: action.id)
                    }
                    group.leave()
                }
            case .updateInventoryItem:
                guard let payload = decodePayload(action.payload),
                      let itemId = payload["itemId"] as? String
                else { return }

                var fields = payload
                fields.removeValue(forKey: "itemId")

                group.enter()
                firebase.updateInventoryItem(itemId: itemId, fields: fields) { result in
                    if case .success = result {
                        self.local.deletePendingAction(id: action.id)
                    }
                    group.leave()
                }
            case .deleteInventoryItem:
                guard let payload = decodePayload(action.payload),
                      let itemId = payload["itemId"] as? String
                else { return }

                group.enter()
                firebase.deleteInventoryItem(itemId: itemId) { result in
                    if case .success = result {
                        self.local.deletePendingAction(id: action.id)
                    }
                    group.leave()
                }
            case .updateUserProfile:
                guard let payload = decodePayload(action.payload),
                      let userId = payload["userId"] as? String
                else { return }

                var fields = payload
                fields.removeValue(forKey: "userId")

                group.enter()
                firebase.updateUserProfile(userId: userId, fields: fields) { result in
                    if case .success = result {
                        self.local.deletePendingAction(id: action.id)
                    }
                    group.leave()
                }
            case .deleteUserProfile:
                guard let payload = decodePayload(action.payload),
                      let userId = payload["userId"] as? String
                else { return }

                group.enter()
                firebase.deleteUserProfile(userId: userId) { result in
                    if case .success = result {
                        self.local.deletePendingAction(id: action.id)
                    }
                    group.leave()
                }
            case .markNotificationRead:
                guard let payload = decodePayload(action.payload),
                      let notificationId = payload["notificationId"] as? String,
                      let isRead = payload["isRead"] as? Bool
                else { return }

                group.enter()
                firebase.updateNotificationRead(notificationId: notificationId, isRead: isRead) { result in
                    if case .success = result {
                        self.local.deletePendingAction(id: action.id)
                    }
                    group.leave()
                }
            case .clearNotifications:
                group.enter()
                firebase.clearNotifications(organizationId: action.organizationId, userId: action.userId) { result in
                    if case .success = result {
                        self.local.deletePendingAction(id: action.id)
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion?()
        }
    }

    private func syncJobs(organizationId: String, completion: (() -> Void)? = nil) {
        firebase.fetchJobs(organizationId: organizationId) { result in
            switch result {
            case .success(let jobs):
                self.local.saveJobs(jobs)
            case .failure:
                break
            }
            completion?()
        }
    }

    private func syncPendingJobPhotos(organizationId: String) {
        let jobs = local.fetchJobs(organizationId: organizationId)
        jobs.forEach { job in
            let localUrls = job.photoUrls.filter { $0.hasPrefix("file://") }
            localUrls.forEach { localUrl in
                guard let data = loadFileData(localUrl) else { return }
                let fileName = "job_\(job.id)_\(UUID().uuidString).jpg"
                firebase.uploadJobPhoto(data: data, fileName: fileName, jobId: job.id) { result in
                    if case .success(let remoteUrl) = result {
                        self.local.replaceJobPhotoUrl(jobId: job.id, from: localUrl, to: remoteUrl)
                    }
                }
            }
        }
    }

    private func syncPendingIssueReports() {
        let reports = local.fetchPendingIssueReports()
        reports.forEach { report in
            uploadIssueReport(report)
        }
    }

    private func uploadIssueReport(_ report: IssueReport) {
        let localUrls = report.attachmentUrls.filter { $0.hasPrefix("file://") }
        if localUrls.isEmpty {
            firebase.createIssueReport(report) { result in
                if case .success = result {
                    self.local.markIssueReportSynced(id: report.id)
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
                attachmentUrls: mergedUrls,
                managerResponse: report.managerResponse,
                resolvedAt: report.resolvedAt
            )
            self.firebase.createIssueReport(updated) { result in
                if case .success = result {
                    self.local.markIssueReportSynced(id: report.id)
                }
            }
        }
    }

    private func loadFileData(_ path: String) -> Data? {
        guard let url = URL(string: path) else { return nil }
        return try? Data(contentsOf: url)
    }

    private func encodePayload(_ payload: [String: Any]) -> Data? {
        try? JSONSerialization.data(withJSONObject: payload, options: [])
    }

    private func decodePayload(_ data: Data) -> [String: Any]? {
        (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any]
    }

    private func jobPayload(_ job: Job) -> [String: Any] {
        var payload: [String: Any] = [
            "id": job.id,
            "organizationId": job.organizationId,
            "title": job.title,
            "location": job.location,
            "scheduledAt": job.scheduledAt.timeIntervalSince1970,
            "status": job.status,
            "priority": job.priority,
            "isUrgent": job.isUrgent,
            "isOnHold": job.isOnHold,
            "assignedUserId": job.assignedUserId,
            "notes": job.notes as Any,
            "approvedCost": job.approvedCost as Any,
            "photoUrls": job.photoUrls,
            "updatedAt": job.updatedAt.timeIntervalSince1970,
            "quotationItems": quotationItemsPayload(job.quotationItems)
        ]

        if let siteLatitude = job.siteLatitude {
            payload["siteLatitude"] = siteLatitude
        }
        if let siteLongitude = job.siteLongitude {
            payload["siteLongitude"] = siteLongitude
        }
        if let holdReason = job.holdReason {
            payload["holdReason"] = holdReason
        }
        if let cancelledAt = job.cancelledAt {
            payload["cancelledAt"] = cancelledAt.timeIntervalSince1970
        }

        return payload
    }

    private func jobFromPayload(_ payload: [String: Any]) -> Job? {
        guard let id = payload["id"] as? String,
              let organizationId = payload["organizationId"] as? String,
              let title = payload["title"] as? String,
              let location = payload["location"] as? String,
              let scheduledAtValue = payload["scheduledAt"] as? TimeInterval,
              let status = payload["status"] as? String,
              let priority = payload["priority"] as? String,
              let isUrgent = payload["isUrgent"] as? Bool,
              let isOnHold = payload["isOnHold"] as? Bool,
              let assignedUserId = payload["assignedUserId"] as? String,
              let updatedAtValue = payload["updatedAt"] as? TimeInterval
        else { return nil }

        let quotationItems = quotationItemsFromPayload(payload["quotationItems"] as? [[String: Any]])
        let cancelledAtValue = payload["cancelledAt"] as? TimeInterval

        return Job(
            id: id,
            organizationId: organizationId,
            title: title,
            location: location,
            siteLatitude: payload["siteLatitude"] as? Double,
            siteLongitude: payload["siteLongitude"] as? Double,
            scheduledAt: Date(timeIntervalSince1970: scheduledAtValue),
            status: status,
            priority: priority,
            isUrgent: isUrgent,
            isOnHold: isOnHold,
            holdReason: payload["holdReason"] as? String,
            cancelledAt: cancelledAtValue.map { Date(timeIntervalSince1970: $0) },
            assignedUserId: assignedUserId,
            notes: payload["notes"] as? String,
            quotationItems: quotationItems,
            approvedCost: payload["approvedCost"] as? Double,
            photoUrls: payload["photoUrls"] as? [String] ?? [],
            updatedAt: Date(timeIntervalSince1970: updatedAtValue)
        )
    }

    private func quotationItemsPayload(_ items: [QuotationItem]) -> [[String: Any]] {
        items.map {
            [
                "id": $0.id,
                "name": $0.name,
                "unitPrice": $0.unitPrice,
                "quantity": $0.quantity,
                "status": $0.status
            ]
        }
    }

    private func quotationItemsFromPayload(_ items: [[String: Any]]?) -> [QuotationItem] {
        guard let items = items else { return [] }
        return items.compactMap { item in
            guard let id = item["id"] as? String,
                  let name = item["name"] as? String,
                  let unitPrice = item["unitPrice"] as? Double,
                  let quantity = item["quantity"] as? Int,
                  let status = item["status"] as? String
            else { return nil }
            return QuotationItem(id: id, name: name, unitPrice: unitPrice, quantity: quantity, status: status)
        }
    }

    private func inventoryItemFromPayload(_ payload: [String: Any]) -> InventoryItem? {
        guard let id = payload["id"] as? String,
              let organizationId = payload["organizationId"] as? String,
              let name = payload["name"] as? String,
              let category = payload["category"] as? String,
              let quantity = payload["quantity"] as? Int,
              let unitPrice = payload["unitPrice"] as? Double
        else { return nil }

        return InventoryItem(
            id: id,
            organizationId: organizationId,
            name: name,
            category: category,
            quantity: quantity,
            unitPrice: unitPrice,
            sku: payload["sku"] as? String,
            imageUrl: payload["imageUrl"] as? String
        )
    }
}
