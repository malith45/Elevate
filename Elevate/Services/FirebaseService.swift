import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import CoreLocation

/**
 * FirebaseService
 * 
 * Central hub for all Firebase-related operations including Authentication, Firestore CRUD,
 * Real-time listeners, and Cloud Messaging configuration.
 */
final class FirebaseService {
    static let shared = FirebaseService()

    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    private init() {}

    func verifyPassword(userId: String, password: String, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            guard error == nil, let data = snapshot?.data() else {
                completion(false)
                return
            }
            let storedPassword = data["password"] as? String ?? ""
            completion(storedPassword == password)
        }
    }

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
                phone: data["phone"] as? String,
                latitude: data["latitude"] as? Double,
                longitude: data["longitude"] as? Double,
                notificationsEnabled: data["notificationsEnabled"] as? Bool ?? true
            )

            if let photoUrl = data["photoUrl"] as? String {
                ProfileImageCache.shared.saveRemoteUrl(photoUrl, for: doc.documentID)
            }

            // Validate password against stored field.
            let storedPassword = data["password"] as? String ?? ""
            if storedPassword != password {
                completion(.failure(NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Incorrect password."])))
                return
            }

            completion(.success(user))
        }
    }

    func isOrganizationIdAvailable(_ organizationId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        db.collection("organizations").document(organizationId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(snapshot?.exists == false))
        }
    }

    func isUsernameAvailable(organizationId: String, username: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        db.collection("users")
            .whereField("organizationId", isEqualTo: organizationId)
            .whereField("username", isEqualTo: username)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(snapshot?.documents.isEmpty ?? true))
            }
    }

    func createOrganization(organizationId: String, name: String, completion: @escaping (Result<OrganizationDetails, Error>) -> Void) {
        let data: [String: Any] = [
            "name": name,
            "createdAt": Timestamp(date: Date())
        ]
        db.collection("organizations").document(organizationId).setData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(OrganizationDetails(id: organizationId, name: name, introduction: nil)))
            }
        }
    }

    func requestPasswordReset(organizationId: String?, identification: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let trimmed = identification.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion(.failure(NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Enter your email or user ID."])))
            return
        }

        if trimmed.contains("@") {
            auth.sendPasswordReset(withEmail: trimmed) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
            return
        }

        guard let organizationId = organizationId, !organizationId.isEmpty else {
            completion(.failure(NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Organization ID is required for user ID reset."])))
            return
        }

        db.collection("users")
            .whereField("organizationId", isEqualTo: organizationId)
            .whereField("username", isEqualTo: trimmed)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let doc = snapshot?.documents.first else {
                    completion(.failure(NSError(domain: "Auth", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found."])))
                    return
                }

                doc.reference.updateData([
                    "passwordResetRequestedAt": Timestamp(date: Date())
                ]) { updateError in
                    if let updateError = updateError {
                        completion(.failure(updateError))
                    } else {
                        // Notify managers
                        let displayName = doc.data()["displayName"] as? String ?? trimmed
                        NotificationManager.shared.notifyManagers(
                            organizationId: organizationId,
                            type: .passwordResetRequest,
                            title: "Password Reset Request",
                            body: "\(displayName) has requested a password reset.",
                            targetId: doc.documentID
                        )
                        completion(.success(()))
                    }
                }
            }
    }

    func resetUserPassword(userId: String, newPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("users").document(userId).updateData([
            "password": newPassword,
            "passwordResetRequestedAt": FieldValue.delete()
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
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
                phone: data["phone"] as? String,
                latitude: data["latitude"] as? Double,
                longitude: data["longitude"] as? Double,
                notificationsEnabled: data["notificationsEnabled"] as? Bool ?? true
            )

            if let photoUrl = data["photoUrl"] as? String {
                ProfileImageCache.shared.saveRemoteUrl(photoUrl, for: snapshot?.documentID ?? userId)
            }
            completion(.success(user))
        }
    }

    func fetchUserPhotoUrl(userId: String, completion: @escaping (Result<String?, Error>) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let url = snapshot?.data()?["photoUrl"] as? String
            completion(.success(url))
        }
    }

    func fetchUsers(organizationId: String, completion: @escaping (Result<[User], Error>) -> Void) {
        db.collection("users")
            .whereField("organizationId", isEqualTo: organizationId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let users = snapshot?.documents.compactMap { doc -> User? in
                    let data = doc.data()
                    if let photoUrl = data["photoUrl"] as? String {
                        ProfileImageCache.shared.saveRemoteUrl(photoUrl, for: doc.documentID)
                    }
                    return User(
                        id: doc.documentID,
                        organizationId: data["organizationId"] as? String ?? "",
                        username: data["username"] as? String ?? "",
                        displayName: data["displayName"] as? String ?? "",
                        role: data["role"] as? String ?? "",
                        email: data["email"] as? String,
                        phone: data["phone"] as? String,
                        latitude: data["latitude"] as? Double,
                        longitude: data["longitude"] as? Double,
                        notificationsEnabled: data["notificationsEnabled"] as? Bool ?? true
                    )
                } ?? []

                completion(.success(users))
            }
    }

    func createUser(organizationId: String, username: String, displayName: String, role: String, email: String?, phone: String?, password: String?, completion: @escaping (Result<User, Error>) -> Void) {
        let doc = db.collection("users").document()
        var data: [String: Any] = [
            "organizationId": organizationId,
            "username": username,
            "displayName": displayName,
            "role": role,
            "createdAt": Timestamp(date: Date())
        ]
        if let email = email { data["email"] = email }
        if let phone = phone { data["phone"] = phone }
        if let password = password {
            data["password"] = password
        }

        doc.setData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                let user = User(
                    id: doc.documentID,
                    organizationId: organizationId,
                    username: username,
                    displayName: displayName,
                    role: role,
                    email: email,
                    phone: phone,
                    latitude: nil,
                    longitude: nil,
                    notificationsEnabled: true
                )
                completion(.success(user))
            }
        }
    }

    func updateUserLocation(userId: String, latitude: Double, longitude: Double) {
        let payload: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "locationUpdatedAt": Timestamp(date: Date())
        ]
        db.collection("users").document(userId).updateData(payload) { _ in }
    }

    func listenToUserLocation(userId: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) -> ListenerRegistration {
        return db.collection("users").document(userId).addSnapshotListener { snapshot, _ in
            guard let data = snapshot?.data(),
                  let lat = data["latitude"] as? Double,
                  let lon = data["longitude"] as? Double else {
                completion(nil)
                return
            }
            completion(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
    }

    func updateUserProfile(userId: String, fields: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        var payload = fields
        payload["updatedAt"] = Timestamp(date: Date())
        db.collection("users").document(userId).updateData(payload) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func deleteUserProfile(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("users").document(userId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func dropOrganization(organizationId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let dispatchGroup = DispatchGroup()
        let collections = ["users", "jobs", "inventory", "issueReports", "notifications"]
        var overallError: Error?

        for collection in collections {
            dispatchGroup.enter()
            db.collection(collection).whereField("organizationId", isEqualTo: organizationId).getDocuments { snapshot, error in
                if let error = error {
                    overallError = error
                    dispatchGroup.leave()
                    return
                }
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    dispatchGroup.leave()
                    return
                }

                let batch = self.db.batch()
                for document in documents {
                    batch.deleteDocument(document.reference)
                }

                batch.commit { error in
                    if let error = error {
                        overallError = error
                    }
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            if let error = overallError {
                completion(.failure(error))
            } else {
                // Finally drop the org doc itself
                self.db.collection("organizations").document(organizationId).delete { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
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
                name: data["name"] as? String ?? "",
                introduction: data["introduction"] as? String
            )
            completion(.success(org))
        }
    }

    func updateOrganization(organizationId: String, name: String?, introduction: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        var payload: [String: Any] = ["updatedAt": Timestamp(date: Date())]
        if let name = name {
            payload["name"] = name
        }
        if let introduction = introduction {
            payload["introduction"] = introduction
        }

        db.collection("organizations").document(organizationId).setData(payload, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func fetchJobs(organizationId: String, assignedUserId: String? = nil, completion: @escaping (Result<[Job], Error>) -> Void) {
        var query: Query = db.collection("jobs")
            .whereField("organizationId", isEqualTo: organizationId)
        
        if let assignedUserId = assignedUserId {
            query = query.whereField("assignedUserId", isEqualTo: assignedUserId)
        }
        
        query.getDocuments { snapshot, error in
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
                    let quotationItems = self.mapQuotationItems(data["quotationItems"] as? [[String: Any]])

                    return Job(
                        id: doc.documentID,
                        organizationId: data["organizationId"] as? String ?? "",
                        title: title,
                        location: location,
                        siteLatitude: data["siteLatitude"] as? Double,
                        siteLongitude: data["siteLongitude"] as? Double,
                        scheduledAt: timestamp.dateValue(),
                        status: status,
                        priority: priority,
                        isUrgent: data["isUrgent"] as? Bool ?? false,
                        isOnHold: data["isOnHold"] as? Bool ?? false,
                        holdReason: data["holdReason"] as? String,
                        cancelledAt: (data["cancelledAt"] as? Timestamp)?.dateValue(),
                        assignedUserId: assignedUserId,
                        notes: data["notes"] as? String,
                        quotationItems: quotationItems,
                        approvedCost: data["approvedCost"] as? Double,
                        photoUrls: data["photoUrls"] as? [String] ?? [],
                        updatedAt: updatedAt
                    )
                } ?? []

                completion(.success(jobs))
            }
    }

    func listenToJobs(organizationId: String, assignedUserId: String, completion: @escaping ([Job]) -> Void) -> ListenerRegistration {
        db.collection("jobs")
            .whereField("organizationId", isEqualTo: organizationId)
            .whereField("assignedUserId", isEqualTo: assignedUserId)
            .addSnapshotListener { snapshot, error in
                guard error == nil, let documents = snapshot?.documents else { return }

                let jobs = documents.compactMap { doc -> Job? in
                    let data = doc.data()
                    guard let title = data["title"] as? String,
                          let location = data["location"] as? String,
                          let status = data["status"] as? String,
                          let priority = data["priority"] as? String,
                          let assignedUserId = data["assignedUserId"] as? String,
                          let timestamp = data["scheduledAt"] as? Timestamp
                    else { return nil }

                    let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? timestamp.dateValue()
                    let quotationItems = self.mapQuotationItems(data["quotationItems"] as? [[String: Any]])

                    return Job(
                        id: doc.documentID,
                        organizationId: data["organizationId"] as? String ?? "",
                        title: title,
                        location: location,
                        siteLatitude: data["siteLatitude"] as? Double,
                        siteLongitude: data["siteLongitude"] as? Double,
                        scheduledAt: timestamp.dateValue(),
                        status: status,
                        priority: priority,
                        isUrgent: data["isUrgent"] as? Bool ?? false,
                        isOnHold: data["isOnHold"] as? Bool ?? false,
                        holdReason: data["holdReason"] as? String,
                        cancelledAt: (data["cancelledAt"] as? Timestamp)?.dateValue(),
                        assignedUserId: assignedUserId,
                        notes: data["notes"] as? String,
                        quotationItems: quotationItems,
                        approvedCost: data["approvedCost"] as? Double,
                        photoUrls: data["photoUrls"] as? [String] ?? [],
                        updatedAt: updatedAt
                    )
                }

                completion(jobs)
            }
    }

    func listenToOrganizationJobs(organizationId: String, completion: @escaping ([Job]) -> Void) -> ListenerRegistration {
        db.collection("jobs")
            .whereField("organizationId", isEqualTo: organizationId)
            .addSnapshotListener { snapshot, error in
                guard error == nil, let documents = snapshot?.documents else { return }

                let jobs = documents.compactMap { doc -> Job? in
                    let data = doc.data()
                    guard let title = data["title"] as? String,
                          let location = data["location"] as? String,
                          let status = data["status"] as? String,
                          let priority = data["priority"] as? String,
                          let assignedUserId = data["assignedUserId"] as? String,
                          let timestamp = data["scheduledAt"] as? Timestamp
                    else { return nil }

                    let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? timestamp.dateValue()
                    let quotationItems = self.mapQuotationItems(data["quotationItems"] as? [[String: Any]])

                    return Job(
                        id: doc.documentID,
                        organizationId: data["organizationId"] as? String ?? "",
                        title: title,
                        location: location,
                        siteLatitude: data["siteLatitude"] as? Double,
                        siteLongitude: data["siteLongitude"] as? Double,
                        scheduledAt: timestamp.dateValue(),
                        status: status,
                        priority: priority,
                        isUrgent: data["isUrgent"] as? Bool ?? false,
                        isOnHold: data["isOnHold"] as? Bool ?? false,
                        holdReason: data["holdReason"] as? String,
                        cancelledAt: (data["cancelledAt"] as? Timestamp)?.dateValue(),
                        assignedUserId: assignedUserId,
                        notes: data["notes"] as? String,
                        quotationItems: quotationItems,
                        approvedCost: data["approvedCost"] as? Double,
                        photoUrls: data["photoUrls"] as? [String] ?? [],
                        updatedAt: updatedAt
                    )
                }

                completion(jobs)
            }
    }

    func listenToJob(jobId: String, completion: @escaping (Job?) -> Void) -> ListenerRegistration {
        db.collection("jobs").document(jobId)
            .addSnapshotListener { snapshot, error in
                guard error == nil, let data = snapshot?.data() else {
                    completion(nil)
                    return
                }

                guard let title = data["title"] as? String,
                      let location = data["location"] as? String,
                      let status = data["status"] as? String,
                      let priority = data["priority"] as? String,
                      let assignedUserId = data["assignedUserId"] as? String,
                      let timestamp = data["scheduledAt"] as? Timestamp
                else {
                    completion(nil)
                    return
                }

                let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? timestamp.dateValue()
                let quotationItems = self.mapQuotationItems(data["quotationItems"] as? [[String: Any]])

                let job = Job(
                    id: snapshot?.documentID ?? jobId,
                    organizationId: data["organizationId"] as? String ?? "",
                    title: title,
                    location: location,
                    siteLatitude: data["siteLatitude"] as? Double,
                    siteLongitude: data["siteLongitude"] as? Double,
                    scheduledAt: timestamp.dateValue(),
                    status: status,
                    priority: priority,
                    isUrgent: data["isUrgent"] as? Bool ?? false,
                    isOnHold: data["isOnHold"] as? Bool ?? false,
                    holdReason: data["holdReason"] as? String,
                    cancelledAt: (data["cancelledAt"] as? Timestamp)?.dateValue(),
                    assignedUserId: assignedUserId,
                    notes: data["notes"] as? String,
                    quotationItems: quotationItems,
                    approvedCost: data["approvedCost"] as? Double,
                    photoUrls: data["photoUrls"] as? [String] ?? [],
                    updatedAt: updatedAt
                )

                completion(job)
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
            let quotationItems = self.mapQuotationItems(data["quotationItems"] as? [[String: Any]])

            let job = Job(
                id: snapshot?.documentID ?? jobId,
                organizationId: data["organizationId"] as? String ?? "",
                title: title,
                location: location,
                siteLatitude: data["siteLatitude"] as? Double,
                siteLongitude: data["siteLongitude"] as? Double,
                scheduledAt: timestamp.dateValue(),
                status: status,
                priority: priority,
                isUrgent: data["isUrgent"] as? Bool ?? false,
                isOnHold: data["isOnHold"] as? Bool ?? false,
                holdReason: data["holdReason"] as? String,
                cancelledAt: (data["cancelledAt"] as? Timestamp)?.dateValue(),
                assignedUserId: assignedUserId,
                notes: data["notes"] as? String,
                quotationItems: quotationItems,
                approvedCost: data["approvedCost"] as? Double,
                photoUrls: data["photoUrls"] as? [String] ?? [],
                updatedAt: updatedAt
            )
            completion(.success(job))
        }
    }

    func createJob(_ job: Job, completion: @escaping (Result<Void, Error>) -> Void) {
        var data: [String: Any] = [
            "organizationId": job.organizationId,
            "title": job.title,
            "location": job.location,
            "scheduledAt": Timestamp(date: job.scheduledAt),
            "status": job.status,
            "priority": job.priority,
            "isUrgent": job.isUrgent,
            "isOnHold": job.isOnHold,
            "assignedUserId": job.assignedUserId,
            "notes": job.notes as Any,
            "approvedCost": job.approvedCost as Any,
            "photoUrls": job.photoUrls,
            "updatedAt": Timestamp(date: job.updatedAt),
            "quotationItems": quotationItemsData(job.quotationItems)
        ]

        if let siteLatitude = job.siteLatitude {
            data["siteLatitude"] = siteLatitude
        }
        if let siteLongitude = job.siteLongitude {
            data["siteLongitude"] = siteLongitude
        }
        if let holdReason = job.holdReason {
            data["holdReason"] = holdReason
        }
        if let cancelledAt = job.cancelledAt {
            data["cancelledAt"] = Timestamp(date: cancelledAt)
        }

        db.collection("jobs").document(job.id).setData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // Removed uploadIssueAttachment, uploadJobPhoto, and uploadInventoryPhoto
    // These are now handled as Base64 strings directly in the documents via ViewModels.

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
                        sku: data["sku"] as? String,
                        imageUrl: data["imageUrl"] as? String
                    )
                } ?? []

                completion(.success(items))
            }
    }

    func createInventoryItem(_ item: InventoryItem, completion: @escaping (Result<Void, Error>) -> Void) {
        let data: [String: Any] = [
            "organizationId": item.organizationId,
            "name": item.name,
            "category": item.category,
            "quantity": item.quantity,
            "unitPrice": item.unitPrice,
            "sku": item.sku as Any,
            "imageUrl": item.imageUrl as Any,
            "updatedAt": Timestamp(date: Date())
        ]

        db.collection("inventory").document(item.id).setData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func updateInventoryItem(itemId: String, fields: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        var payload = fields
        payload["updatedAt"] = Timestamp(date: Date())
        db.collection("inventory").document(itemId).updateData(payload) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func deleteInventoryItem(itemId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("inventory").document(itemId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func submitQuotationRequest(jobId: String, userId: String, items: [QuotationItem], completion: @escaping (Result<Void, Error>) -> Void) {
        fetchJob(jobId: jobId) { result in
            switch result {
            case .success(let job):
                let merged = self.mergeQuotationItems(existing: job.quotationItems, new: items)
                let payload: [String: Any] = [
                    "quotationItems": self.quotationItemsData(merged),
                    "updatedAt": Timestamp(date: Date())
                ]
                self.db.collection("jobs").document(jobId).updateData(payload) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            case .failure:
                let payload: [String: Any] = [
                    "quotationItems": FieldValue.arrayUnion(self.quotationItemsData(items)),
                    "updatedAt": Timestamp(date: Date())
                ]
                self.db.collection("jobs").document(jobId).updateData(payload) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }

    func fetchQuotationItems(jobId: String, completion: @escaping (Result<[QuotationItem], Error>) -> Void) {
        fetchJob(jobId: jobId) { result in
            switch result {
            case .success(let job):
                completion(.success(job.quotationItems))
            case .failure(let error):
                completion(.failure(error))
            }
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
            "attachmentUrls": report.attachmentUrls,
            "managerResponse": report.managerResponse as Any,
            "resolvedAt": report.resolvedAt.map { Timestamp(date: $0) } as Any
        ]

        db.collection("issueReports").document(report.id).setData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func fetchIssueReports(jobId: String, completion: @escaping (Result<[IssueReport], Error>) -> Void) {
        db.collection("issueReports")
            .whereField("jobId", isEqualTo: jobId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let reports = snapshot?.documents.compactMap { doc -> IssueReport? in
                    let data = doc.data()
                    guard let jobId = data["jobId"] as? String,
                          let userId = data["userId"] as? String,
                          let organizationId = data["organizationId"] as? String,
                          let description = data["description"] as? String,
                          let priority = data["priority"] as? String,
                          let createdAt = data["createdAt"] as? Timestamp
                    else { return nil }

                    return IssueReport(
                        id: doc.documentID,
                        jobId: jobId,
                        userId: userId,
                        organizationId: organizationId,
                        description: description,
                        priority: priority,
                        createdAt: createdAt.dateValue(),
                        attachmentUrls: data["attachmentUrls"] as? [String] ?? [],
                        managerResponse: data["managerResponse"] as? String,
                        resolvedAt: (data["resolvedAt"] as? Timestamp)?.dateValue()
                    )
                } ?? []

                completion(.success(reports))
            }
    }

    func updateIssueReportResponse(reportId: String, response: String, resolvedAt: Date?, completion: @escaping (Result<Void, Error>) -> Void) {
        var payload: [String: Any] = [
            "managerResponse": response,
            "respondedAt": Timestamp(date: Date())
        ]
        if let resolvedAt = resolvedAt {
            payload["resolvedAt"] = Timestamp(date: resolvedAt)
        }

        db.collection("issueReports").document(reportId).updateData(payload) { error in
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

    func updateJobFields(jobId: String, fields: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        var payload = fields
        payload["updatedAt"] = Timestamp(date: Date())
        db.collection("jobs").document(jobId).updateData(payload) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func updateQuotationItems(jobId: String, items: [QuotationItem], approvedCost: Double?, completion: @escaping (Result<Void, Error>) -> Void) {
        var payload: [String: Any] = [
            "quotationItems": quotationItemsData(items),
            "updatedAt": Timestamp(date: Date())
        ]
        if let approvedCost = approvedCost {
            payload["approvedCost"] = approvedCost
        }

        db.collection("jobs").document(jobId).updateData(payload) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    private func mapQuotationItems(_ items: [[String: Any]]?) -> [QuotationItem] {
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

    private func quotationItemsData(_ items: [QuotationItem]) -> [[String: Any]] {
        items.map { item in
            [
                "id": item.id,
                "name": item.name,
                "unitPrice": item.unitPrice,
                "quantity": item.quantity,
                "status": item.status
            ]
        }
    }

    private func mergeQuotationItems(existing: [QuotationItem], new: [QuotationItem]) -> [QuotationItem] {
        var merged = existing
        new.forEach { item in
            if let index = merged.firstIndex(where: { $0.id == item.id }) {
                merged[index] = item
            } else {
                merged.append(item)
            }
        }
        return merged
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
                        targetId: data["targetId"] as? String,
                        createdAt: timestamp.dateValue(),
                        isRead: data["isRead"] as? Bool ?? false
                    )
                } ?? []

                completion(.success(items))
            }
    }

    func updateNotificationRead(notificationId: String, isRead: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("notifications").document(notificationId).updateData([
            "isRead": isRead,
            "readAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func clearNotifications(organizationId: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("notifications")
            .whereField("organizationId", isEqualTo: organizationId)
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    completion(.success(()))
                    return
                }

                let batch = self.db.batch()
                documents.forEach { batch.deleteDocument($0.reference) }
                batch.commit { commitError in
                    if let commitError = commitError {
                        completion(.failure(commitError))
                    } else {
                        completion(.success(()))
                    }
                }
            }
    }

    func createNotification(organizationId: String, userId: String, title: String, body: String, type: String, targetId: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        let payload: [String: Any] = [
            "organizationId": organizationId,
            "userId": userId,
            "title": title,
            "body": body,
            "type": type,
            "targetId": targetId as Any,
            "createdAt": Timestamp(date: Date()),
            "isRead": false
        ]

        db.collection("notifications").document().setData(payload) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func saveFcmToken(userId: String, token: String) {
        db.collection("users").document(userId).setData([
            "fcmToken": token,
            "fcmUpdatedAt": Timestamp(date: Date())
        ], merge: true)
    }

    // MARK: - Real-time listeners for inventory, users, and notifications

    func listenToInventory(organizationId: String, completion: @escaping ([InventoryItem]) -> Void) -> ListenerRegistration {
        db.collection("inventory")
            .whereField("organizationId", isEqualTo: organizationId)
            .addSnapshotListener { snapshot, error in
                guard error == nil, let documents = snapshot?.documents else { return }
                let items = documents.compactMap { doc -> InventoryItem? in
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
                        sku: data["sku"] as? String,
                        imageUrl: data["imageUrl"] as? String
                    )
                }
                completion(items)
            }
    }

    func listenToUsers(organizationId: String, completion: @escaping ([User]) -> Void) -> ListenerRegistration {
        db.collection("users")
            .whereField("organizationId", isEqualTo: organizationId)
            .addSnapshotListener { snapshot, error in
                guard error == nil, let documents = snapshot?.documents else { return }
                let users = documents.compactMap { doc -> User? in
                    let data = doc.data()
                    if let photoUrl = data["photoUrl"] as? String {
                        ProfileImageCache.shared.saveRemoteUrl(photoUrl, for: doc.documentID)
                    }
                    return User(
                        id: doc.documentID,
                        organizationId: data["organizationId"] as? String ?? "",
                        username: data["username"] as? String ?? "",
                        displayName: data["displayName"] as? String ?? "",
                        role: data["role"] as? String ?? "",
                        email: data["email"] as? String,
                        phone: data["phone"] as? String,
                        latitude: data["latitude"] as? Double,
                        longitude: data["longitude"] as? Double,
                        notificationsEnabled: data["notificationsEnabled"] as? Bool ?? true
                    )
                }
                completion(users)
            }
    }

    func listenToNotifications(organizationId: String, userId: String, completion: @escaping ([NotificationItem]) -> Void) -> ListenerRegistration {
        db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                guard error == nil, let documents = snapshot?.documents else { return }
                let items = documents.compactMap { doc -> NotificationItem? in
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
                        targetId: data["targetId"] as? String,
                        createdAt: timestamp.dateValue(),
                        isRead: data["isRead"] as? Bool ?? false
                    )
                }
                completion(items)
            }
    }

    func deleteJob(jobId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("jobs").document(jobId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func deleteIssueReportsForJob(jobId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("issueReports").whereField("jobId", isEqualTo: jobId).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                completion(.success(()))
                return
            }
            
            let batch = self.db.batch()
            documents.forEach { batch.deleteDocument($0.reference) }
            
            batch.commit { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
}
