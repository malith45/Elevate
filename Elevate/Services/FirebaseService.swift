import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import FirebaseStorage

final class FirebaseService {
    static let shared = FirebaseService()

    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private init() {}

    func signIn(organizationId: String, username: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        // Example: auth using Firebase Auth email/password or custom Firestore user collection.
        // This sample assumes a users collection keyed by username + orgId.
        let query = db.collection("users")
            .whereField("organizationId", isEqualTo: organizationId)
            .whereField("username", isEqualTo: username)
            .limit(to: 1)

        query.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let doc = snapshot?.documents.first else {
                completion(.failure(NSError(domain: "Auth", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found."])) )
                return
            }

            let data = doc.data()
            let user = User(
                id: doc.documentID,
                organizationId: data["organizationId"] as? String ?? "",
                username: data["username"] as? String ?? "",
                displayName: data["displayName"] as? String ?? "",
                role: data["role"] as? String ?? "",
                email: data["email"] as? String,
                phone: data["phone"] as? String
            )

            // Optional: validate password against auth provider or a hashed field.
            completion(.success(user))
        }
    }

    func fetchUser(userId: String, completion: @escaping (Result<User, Error>) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = snapshot?.data() else {
                completion(.failure(NSError(domain: "User", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found."])))
                return
            }

            let user = User(
                id: snapshot?.documentID ?? userId,
                organizationId: data["organizationId"] as? String ?? "",
                username: data["username"] as? String ?? "",
                displayName: data["displayName"] as? String ?? "",
                role: data["role"] as? String ?? "",
                email: data["email"] as? String,
                phone: data["phone"] as? String
            )
            completion(.success(user))
        }
    }

    func fetchOrganization(organizationId: String, completion: @escaping (Result<OrganizationDetails, Error>) -> Void) {
        db.collection("organizations").document(organizationId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = snapshot?.data() else {
                completion(.failure(NSError(domain: "Organization", code: 404, userInfo: [NSLocalizedDescriptionKey: "Organization not found."])))
                return
            }

            let org = OrganizationDetails(
                id: snapshot?.documentID ?? organizationId,
                name: data["name"] as? String ?? ""
            )
            completion(.success(org))
        }
    }

    func fetchJobs(organizationId: String, completion: @escaping (Result<[Job], Error>) -> Void) {
        db.collection("jobs")
            .whereField("organizationId", isEqualTo: organizationId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let jobs = snapshot?.documents.compactMap { doc -> Job? in
                    let data = doc.data()
                    guard let title = data["title"] as? String,
                          let location = data["location"] as? String,
                          let status = data["status"] as? String,
                          let priority = data["priority"] as? String,
                          let assignedUserId = data["assignedUserId"] as? String,
                          let timestamp = data["scheduledAt"] as? Timestamp
                    else { return nil }

                    let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? timestamp.dateValue()

                    return Job(
                        id: doc.documentID,
                        organizationId: data["organizationId"] as? String ?? "",
                        title: title,
                        location: location,
                        scheduledAt: timestamp.dateValue(),
                        status: status,
                        priority: priority,
                        assignedUserId: assignedUserId,
                        notes: data["notes"] as? String,
                        approvedCost: data["approvedCost"] as? Double,
                        photoUrls: data["photoUrls"] as? [String] ?? [],
                        updatedAt: updatedAt
                    )
                } ?? []

                completion(.success(jobs))
            }
    }

    func fetchJob(jobId: String, completion: @escaping (Result<Job, Error>) -> Void) {
        db.collection("jobs").document(jobId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = snapshot?.data(),
                  let title = data["title"] as? String,
                  let location = data["location"] as? String,
                  let status = data["status"] as? String,
                  let priority = data["priority"] as? String,
                  let assignedUserId = data["assignedUserId"] as? String,
                  let timestamp = data["scheduledAt"] as? Timestamp
            else {
                completion(.failure(NSError(domain: "Job", code: 404, userInfo: [NSLocalizedDescriptionKey: "Job not found."])))
                return
            }

            let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? timestamp.dateValue()

            let job = Job(
                id: snapshot?.documentID ?? jobId,
                organizationId: data["organizationId"] as? String ?? "",
                title: title,
                location: location,
                scheduledAt: timestamp.dateValue(),
                status: status,
                priority: priority,
                assignedUserId: assignedUserId,
                notes: data["notes"] as? String,
                approvedCost: data["approvedCost"] as? Double,
                photoUrls: data["photoUrls"] as? [String] ?? [],
                updatedAt: updatedAt
            )
            completion(.success(job))
        }
    }

    func uploadIssueAttachment(data: Data, fileName: String, completion: @escaping (Result<String, Error>) -> Void) {
        let ref = storage.reference().child("issueAttachments/\(fileName)")
        ref.putData(data, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            ref.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(url?.absoluteString ?? ""))
            }
        }
    }

    func uploadJobPhoto(data: Data, fileName: String, jobId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let ref = storage.reference().child("jobPhotos/\(jobId)/\(fileName)")
        ref.putData(data, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            ref.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                let urlString = url?.absoluteString ?? ""
                self.db.collection("jobs").document(jobId).updateData([
                    "photoUrls": FieldValue.arrayUnion([urlString])
                ]) { updateError in
                    if let updateError = updateError {
                        completion(.failure(updateError))
                    } else {
                        completion(.success(urlString))
                    }
                }
            }
        }
    }

    func fetchInventoryItems(organizationId: String, completion: @escaping (Result<[InventoryItem], Error>) -> Void) {
        db.collection("inventory")
            .whereField("organizationId", isEqualTo: organizationId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                let items = snapshot?.documents.compactMap { doc -> InventoryItem? in
                    let data = doc.data()
                    guard let name = data["name"] as? String,
                          let category = data["category"] as? String,
                          let quantity = data["quantity"] as? Int,
                          let unitPrice = data["unitPrice"] as? Double
                    else { return nil }

                    return InventoryItem(
                        id: doc.documentID,
                        organizationId: data["organizationId"] as? String ?? "",
                        name: name,
                        category: category,
                        quantity: quantity,
                        unitPrice: unitPrice,
                        sku: data["sku"] as? String
                    )
                } ?? []

                completion(.success(items))
            }
    }

    func submitQuotationRequest(jobId: String, userId: String, items: [QuotationItem], completion: @escaping (Result<Void, Error>) -> Void) {
        let data: [[String: Any]] = items.map { item in
            [
                "id": item.id,
                "name": item.name,
                "unitPrice": item.unitPrice,
                "quantity": item.quantity,
                "status": item.status
            ]
        }

        db.collection("quotationRequests").document(jobId).setData([
            "jobId": jobId,
            "userId": userId,
            "items": data,
            "updatedAt": Timestamp(date: Date())
        ], merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func fetchQuotationItems(jobId: String, completion: @escaping (Result<[QuotationItem], Error>) -> Void) {
        db.collection("quotationRequests").document(jobId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = snapshot?.data(), let items = data["items"] as? [[String: Any]] else {
                completion(.success([]))
                return
            }

            let mapped: [QuotationItem] = items.compactMap { item in
                guard let id = item["id"] as? String,
                      let name = item["name"] as? String,
                      let unitPrice = item["unitPrice"] as? Double,
                      let quantity = item["quantity"] as? Int,
                      let status = item["status"] as? String
                else { return nil }
                return QuotationItem(id: id, name: name, unitPrice: unitPrice, quantity: quantity, status: status)
            }

            completion(.success(mapped))
        }
    }

    func createIssueReport(_ report: IssueReport, completion: @escaping (Result<Void, Error>) -> Void) {
        let data: [String: Any] = [
            "jobId": report.jobId,
            "userId": report.userId,
            "organizationId": report.organizationId,
            "description": report.description,
            "priority": report.priority,
            "createdAt": Timestamp(date: report.createdAt),
            "attachmentUrls": report.attachmentUrls
        ]

        db.collection("issueReports").document(report.id).setData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func updateJobStatus(jobId: String, status: String, updatedAt: Date, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("jobs").document(jobId).updateData([
            "status": status,
            "updatedAt": Timestamp(date: updatedAt)
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func fetchNotifications(organizationId: String, userId: String, completion: @escaping (Result<[NotificationItem], Error>) -> Void) {
        db.collection("notifications")
            .whereField("organizationId", isEqualTo: organizationId)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let items = snapshot?.documents.compactMap { doc -> NotificationItem? in
                    let data = doc.data()
                    guard let title = data["title"] as? String,
                          let body = data["body"] as? String,
                          let type = data["type"] as? String,
                          let timestamp = data["createdAt"] as? Timestamp
                    else { return nil }

                    return NotificationItem(
                        id: doc.documentID,
                        organizationId: data["organizationId"] as? String ?? "",
                        userId: data["userId"] as? String ?? "",
                        title: title,
                        body: body,
                        type: type,
                        createdAt: timestamp.dateValue(),
                        isRead: data["isRead"] as? Bool ?? false
                    )
                } ?? []

                completion(.success(items))
            }
    }

    func saveFcmToken(userId: String, token: String) {
        db.collection("users").document(userId).setData([
            "fcmToken": token,
            "fcmUpdatedAt": Timestamp(date: Date())
        ], merge: true)
    }
}
