import Foundation
import FirebaseFirestore

final class NotificationManager {
    static let shared = NotificationManager()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    enum NotificationType: String {
        case jobAssigned = "JOB_ASSIGNED"
        case jobCancelled = "JOB_CANCELLED"
        case jobStarted = "JOB_STARTED"
        case jobHold = "JOB_HOLD"
        case jobCompleted = "JOB_COMPLETED"
        case quoteSubmitted = "QUOTE_SUBMITTED"
        case quoteApproved = "QUOTE_APPROVED"
        case quoteRejected = "QUOTE_REJECTED"
        case issueReported = "ISSUE_REPORTED"
        case issueResolved = "ISSUE_RESOLVED"
        case issueCommented = "ISSUE_COMMENTED"
        case criticalInventory = "CRITICAL_INVENTORY"
        case passwordResetRequest = "PASSWORD_RESET"
    }
    
    func sendNotification(
        to userId: String,
        organizationId: String,
        type: NotificationType,
        title: String,
        body: String,
        targetId: String? = nil
    ) {
        // First check if the user has notifications enabled
        db.collection("users").document(userId).getDocument { snapshot, error in
            let data = snapshot?.data()
            let enabled = data?["notificationsEnabled"] as? Bool ?? true
            
            print("🔔 [NotificationManager] Checking preferences for \(userId): enabled=\(enabled)")
            
            guard enabled else {
                print("🔔 [NotificationManager] Notifications disabled for user \(userId), skipping.")
                return
            }
            
            // Create the notification record
            let docId = UUID().uuidString
            let notification: [String: Any] = [
                "id": docId,
                "organizationId": organizationId,
                "userId": userId,
                "title": title,
                "body": body,
                "type": type.rawValue,
                "targetId": targetId as Any,
                "createdAt": Timestamp(date: Date()),
                "isRead": false,
                "sound": "default"
            ]
            
            self.db.collection("notifications").document(docId).setData(notification) { err in
                if let err = err {
                    print("❌ [NotificationManager] Error saving notification: \(err.localizedDescription)")
                } else {
                    print("✅ [NotificationManager] Notification saved for user: \(userId)")
                }
            }
            
            // No local feedback here to avoid 'phantom notification' confusion.
            // Notifications should only play sound/haptics when RECEIVED.
        }
    }
    
    // Helper for broadcasting to all managers
    func notifyManagers(
        organizationId: String,
        type: NotificationType,
        title: String,
        body: String,
        targetId: String? = nil
    ) {
        print("🔔 [NotificationManager] Notifying managers for organization: \(organizationId)")
        db.collection("users")
            .whereField("organizationId", isEqualTo: organizationId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ [NotificationManager] Error fetching managers: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { 
                    print("🔔 [NotificationManager] No users found in organization.")
                    return 
                }
                
                let managers = documents.filter { doc in
                    let role = (doc.data()["role"] as? String)?.uppercased() ?? ""
                    return role == "MANAGER" || role == "OWNER"
                }
                
                print("🔔 [NotificationManager] Found \(managers.count) managers to notify")
                
                for doc in managers {
                    self.sendNotification(
                        to: doc.documentID,
                        organizationId: organizationId,
                        type: type,
                        title: title,
                        body: body,
                        targetId: targetId
                    )
                }
            }
    }
}
