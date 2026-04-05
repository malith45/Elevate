import Foundation
import Combine
import CoreData

final class LocalStorageService {
    static let shared = LocalStorageService()

    private let stack = CoreDataStack.shared

    private init() {}

    func saveUser(_ user: User) {
        let context = stack.viewContext
        let entity = NSEntityDescription.insertNewObject(forEntityName: "UserEntity", into: context)
        entity.setValue(user.id, forKey: "id")
        entity.setValue(user.organizationId, forKey: "organizationId")
        entity.setValue(user.username, forKey: "username")
        entity.setValue(user.displayName, forKey: "displayName")
        entity.setValue(user.role, forKey: "role")
        entity.setValue(user.email, forKey: "email")
        entity.setValue(user.phone, forKey: "phone")
        saveContext(context)
    }

    func fetchUser(id: String) -> User? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "UserEntity")
        request.predicate = NSPredicate(format: "id == %@", id)
        guard let result = try? stack.viewContext.fetch(request).first else { return nil }
        return User(
            id: result.value(forKey: "id") as? String ?? "",
            organizationId: result.value(forKey: "organizationId") as? String ?? "",
            username: result.value(forKey: "username") as? String ?? "",
            displayName: result.value(forKey: "displayName") as? String ?? "",
            role: result.value(forKey: "role") as? String ?? "",
            email: result.value(forKey: "email") as? String,
            phone: result.value(forKey: "phone") as? String
        )
    }

    func saveJobs(_ jobs: [Job]) {
        let context = stack.newBackgroundContext()
        context.perform {
            jobs.forEach { job in
                let request = NSFetchRequest<NSManagedObject>(entityName: "JobEntity")
                request.predicate = NSPredicate(format: "id == %@", job.id)
                let entity = (try? context.fetch(request).first) ?? NSEntityDescription.insertNewObject(forEntityName: "JobEntity", into: context)
                if let existingUpdatedAt = entity.value(forKey: "updatedAt") as? Date, existingUpdatedAt > job.updatedAt {
                    return
                }
                entity.setValue(job.id, forKey: "id")
                entity.setValue(job.organizationId, forKey: "organizationId")
                entity.setValue(job.title, forKey: "title")
                entity.setValue(job.location, forKey: "location")
                entity.setValue(job.scheduledAt, forKey: "scheduledAt")
                entity.setValue(job.status, forKey: "status")
                entity.setValue(job.priority, forKey: "priority")
                entity.setValue(job.assignedUserId, forKey: "assignedUserId")
                entity.setValue(job.notes, forKey: "notes")
                entity.setValue(job.approvedCost, forKey: "approvedCost")
                entity.setValue(job.photoUrls, forKey: "photoUrls")
                entity.setValue(job.updatedAt, forKey: "updatedAt")
            }
            self.saveContext(context)
        }
    }

    func fetchJobs(organizationId: String) -> [Job] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "JobEntity")
        request.predicate = NSPredicate(format: "organizationId == %@", organizationId)
        let results = (try? stack.viewContext.fetch(request)) ?? []
        return results.map { item in
            Job(
                id: item.value(forKey: "id") as? String ?? "",
                organizationId: item.value(forKey: "organizationId") as? String ?? "",
                title: item.value(forKey: "title") as? String ?? "",
                location: item.value(forKey: "location") as? String ?? "",
                scheduledAt: item.value(forKey: "scheduledAt") as? Date ?? Date(),
                status: item.value(forKey: "status") as? String ?? "",
                priority: item.value(forKey: "priority") as? String ?? "",
                assignedUserId: item.value(forKey: "assignedUserId") as? String ?? "",
                notes: item.value(forKey: "notes") as? String,
                approvedCost: item.value(forKey: "approvedCost") as? Double,
                photoUrls: item.value(forKey: "photoUrls") as? [String] ?? [],
                updatedAt: item.value(forKey: "updatedAt") as? Date ?? (item.value(forKey: "scheduledAt") as? Date ?? Date())
            )
        }
    }

    func fetchJob(id: String) -> Job? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "JobEntity")
        request.predicate = NSPredicate(format: "id == %@", id)
        guard let item = try? stack.viewContext.fetch(request).first else { return nil }
        return Job(
            id: item.value(forKey: "id") as? String ?? "",
            organizationId: item.value(forKey: "organizationId") as? String ?? "",
            title: item.value(forKey: "title") as? String ?? "",
            location: item.value(forKey: "location") as? String ?? "",
            scheduledAt: item.value(forKey: "scheduledAt") as? Date ?? Date(),
            status: item.value(forKey: "status") as? String ?? "",
            priority: item.value(forKey: "priority") as? String ?? "",
            assignedUserId: item.value(forKey: "assignedUserId") as? String ?? "",
            notes: item.value(forKey: "notes") as? String,
            approvedCost: item.value(forKey: "approvedCost") as? Double,
            photoUrls: item.value(forKey: "photoUrls") as? [String] ?? [],
            updatedAt: item.value(forKey: "updatedAt") as? Date ?? (item.value(forKey: "scheduledAt") as? Date ?? Date())
        )
    }

    func updateJobStatus(id: String, status: String, updatedAt: Date) {
        let context = stack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "JobEntity")
        request.predicate = NSPredicate(format: "id == %@", id)
        guard let item = try? context.fetch(request).first else { return }
        item.setValue(status, forKey: "status")
        item.setValue(updatedAt, forKey: "updatedAt")
        saveContext(context)
    }

    func appendJobPhotoUrl(jobId: String, url: String) {
        let context = stack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "JobEntity")
        request.predicate = NSPredicate(format: "id == %@", jobId)
        guard let item = try? context.fetch(request).first else { return }
        let existing = item.value(forKey: "photoUrls") as? [String] ?? []
        let updated = existing + [url]
        item.setValue(updated, forKey: "photoUrls")
        saveContext(context)
    }

    func replaceJobPhotoUrl(jobId: String, from oldUrl: String, to newUrl: String) {
        let context = stack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "JobEntity")
        request.predicate = NSPredicate(format: "id == %@", jobId)
        guard let item = try? context.fetch(request).first else { return }
        let existing = item.value(forKey: "photoUrls") as? [String] ?? []
        let updated = existing.map { $0 == oldUrl ? newUrl : $0 }
        item.setValue(updated, forKey: "photoUrls")
        saveContext(context)
    }

    func saveInventoryItems(_ items: [InventoryItem]) {
        let context = stack.newBackgroundContext()
        context.perform {
            items.forEach { item in
                let request = NSFetchRequest<NSManagedObject>(entityName: "InventoryItemEntity")
                request.predicate = NSPredicate(format: "id == %@", item.id)
                let entity = (try? context.fetch(request).first) ?? NSEntityDescription.insertNewObject(forEntityName: "InventoryItemEntity", into: context)
                entity.setValue(item.id, forKey: "id")
                entity.setValue(item.organizationId, forKey: "organizationId")
                entity.setValue(item.name, forKey: "name")
                entity.setValue(item.category, forKey: "category")
                entity.setValue(item.quantity, forKey: "quantity")
                entity.setValue(item.unitPrice, forKey: "unitPrice")
                entity.setValue(item.sku, forKey: "sku")
            }
            self.saveContext(context)
        }
    }

    func fetchInventoryItems(organizationId: String) -> [InventoryItem] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "InventoryItemEntity")
        request.predicate = NSPredicate(format: "organizationId == %@", organizationId)
        let results = (try? stack.viewContext.fetch(request)) ?? []
        return results.map { item in
            InventoryItem(
                id: item.value(forKey: "id") as? String ?? "",
                organizationId: item.value(forKey: "organizationId") as? String ?? "",
                name: item.value(forKey: "name") as? String ?? "",
                category: item.value(forKey: "category") as? String ?? "",
                quantity: Int(item.value(forKey: "quantity") as? Int64 ?? 0),
                unitPrice: item.value(forKey: "unitPrice") as? Double ?? 0,
                sku: item.value(forKey: "sku") as? String
            )
        }
    }

    func saveIssueReport(_ report: IssueReport, isSynced: Bool) {
        let context = stack.viewContext
        let entity = NSEntityDescription.insertNewObject(forEntityName: "IssueReportEntity", into: context)
        entity.setValue(report.id, forKey: "id")
        entity.setValue(report.jobId, forKey: "jobId")
        entity.setValue(report.userId, forKey: "userId")
        entity.setValue(report.organizationId, forKey: "organizationId")
        entity.setValue(report.description, forKey: "detail")
        entity.setValue(report.priority, forKey: "priority")
        entity.setValue(report.createdAt, forKey: "createdAt")
        entity.setValue(report.attachmentUrls, forKey: "attachmentUrls")
        entity.setValue(isSynced, forKey: "isSynced")
        saveContext(context)
    }

    func fetchPendingIssueReports() -> [IssueReport] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "IssueReportEntity")
        request.predicate = NSPredicate(format: "isSynced == NO")
        let results = (try? stack.viewContext.fetch(request)) ?? []
        return results.map { item in
            IssueReport(
                id: item.value(forKey: "id") as? String ?? "",
                jobId: item.value(forKey: "jobId") as? String ?? "",
                userId: item.value(forKey: "userId") as? String ?? "",
                organizationId: item.value(forKey: "organizationId") as? String ?? "",
                description: item.value(forKey: "detail") as? String ?? "",
                priority: item.value(forKey: "priority") as? String ?? "",
                createdAt: item.value(forKey: "createdAt") as? Date ?? Date(),
                attachmentUrls: item.value(forKey: "attachmentUrls") as? [String] ?? []
            )
        }
    }

    func markIssueReportSynced(id: String) {
        let context = stack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "IssueReportEntity")
        request.predicate = NSPredicate(format: "id == %@", id)
        guard let item = try? context.fetch(request).first else { return }
        item.setValue(true, forKey: "isSynced")
        saveContext(context)
    }

    func saveNotifications(_ items: [NotificationItem]) {
        let context = stack.newBackgroundContext()
        context.perform {
            items.forEach { item in
                let request = NSFetchRequest<NSManagedObject>(entityName: "NotificationEntity")
                request.predicate = NSPredicate(format: "id == %@", item.id)
                let entity = (try? context.fetch(request).first) ?? NSEntityDescription.insertNewObject(forEntityName: "NotificationEntity", into: context)
                entity.setValue(item.id, forKey: "id")
                entity.setValue(item.organizationId, forKey: "organizationId")
                entity.setValue(item.userId, forKey: "userId")
                entity.setValue(item.title, forKey: "title")
                entity.setValue(item.body, forKey: "body")
                entity.setValue(item.type, forKey: "type")
                entity.setValue(item.createdAt, forKey: "createdAt")
                entity.setValue(item.isRead, forKey: "isRead")
            }
            self.saveContext(context)
        }
    }

    func fetchNotifications(organizationId: String, userId: String) -> [NotificationItem] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "NotificationEntity")
        request.predicate = NSPredicate(format: "organizationId == %@ AND userId == %@", organizationId, userId)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        let results = (try? stack.viewContext.fetch(request)) ?? []
        return results.map { item in
            NotificationItem(
                id: item.value(forKey: "id") as? String ?? "",
                organizationId: item.value(forKey: "organizationId") as? String ?? "",
                userId: item.value(forKey: "userId") as? String ?? "",
                title: item.value(forKey: "title") as? String ?? "",
                body: item.value(forKey: "body") as? String ?? "",
                type: item.value(forKey: "type") as? String ?? "",
                createdAt: item.value(forKey: "createdAt") as? Date ?? Date(),
                isRead: item.value(forKey: "isRead") as? Bool ?? false
            )
        }
    }

    func markNotificationRead(id: String) {
        let context = stack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "NotificationEntity")
        request.predicate = NSPredicate(format: "id == %@", id)
        guard let item = try? context.fetch(request).first else { return }
        item.setValue(true, forKey: "isRead")
        saveContext(context)
    }

    func clearNotifications(organizationId: String, userId: String) {
        let context = stack.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "NotificationEntity")
        request.predicate = NSPredicate(format: "organizationId == %@ AND userId == %@", organizationId, userId)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        _ = try? context.execute(deleteRequest)
        saveContext(context)
    }

    func enqueuePendingAction(_ action: PendingAction) {
        let context = stack.viewContext
        let entity = NSEntityDescription.insertNewObject(forEntityName: "PendingActionEntity", into: context)
        entity.setValue(action.id, forKey: "id")
        entity.setValue(action.organizationId, forKey: "organizationId")
        entity.setValue(action.userId, forKey: "userId")
        entity.setValue(action.type.rawValue, forKey: "type")
        entity.setValue(action.payload, forKey: "payload")
        entity.setValue(action.createdAt, forKey: "createdAt")
        saveContext(context)
    }

    func fetchPendingActions(organizationId: String, userId: String) -> [PendingAction] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "PendingActionEntity")
        request.predicate = NSPredicate(format: "organizationId == %@ AND userId == %@", organizationId, userId)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        let results = (try? stack.viewContext.fetch(request)) ?? []
        return results.compactMap { item in
            guard let id = item.value(forKey: "id") as? String,
                  let orgId = item.value(forKey: "organizationId") as? String,
                  let userId = item.value(forKey: "userId") as? String,
                  let typeRaw = item.value(forKey: "type") as? String,
                  let type = PendingActionType(rawValue: typeRaw),
                  let payload = item.value(forKey: "payload") as? Data,
                  let createdAt = item.value(forKey: "createdAt") as? Date
            else { return nil }

            return PendingAction(
                id: id,
                organizationId: orgId,
                userId: userId,
                type: type,
                payload: payload,
                createdAt: createdAt
            )
        }
    }

    func deletePendingAction(id: String) {
        let context = stack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "PendingActionEntity")
        request.predicate = NSPredicate(format: "id == %@", id)
        if let item = try? context.fetch(request).first {
            context.delete(item)
            saveContext(context)
        }
    }

    func pendingActionsCount(organizationId: String, userId: String) -> Int {
        let request = NSFetchRequest<NSManagedObject>(entityName: "PendingActionEntity")
        request.predicate = NSPredicate(format: "organizationId == %@ AND userId == %@", organizationId, userId)
        return (try? stack.viewContext.fetch(request).count) ?? 0
    }

    func saveImageData(_ data: Data, fileName: String) -> String? {
        let fileManager = FileManager.default
        guard let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let url = docs.appendingPathComponent(fileName)
        do {
            try data.write(to: url)
            return url.absoluteString
        } catch {
            return nil
        }
    }

    func saveContext(_ context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Core Data save error: \(error)")
        }
    }
}
