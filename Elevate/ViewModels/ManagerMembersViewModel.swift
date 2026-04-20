import Foundation
import Combine
import UIKit

final class ManagerMembersViewModel: ObservableObject {
    @Published var members: [User] = []
    @Published var errorMessage: String?

    private let localStorage = LocalStorageService.shared
    private let firebase = FirebaseService.shared

    func load(organizationId: String, isOnline: Bool) {
        members = localStorage.fetchUsers(organizationId: organizationId)

        guard isOnline else { return }
        firebase.fetchUsers(organizationId: organizationId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let users):
                    self.localStorage.saveUsers(users)
                    self.members = users
                    // Sync each member's profile photo URL into the local cache
                    users.forEach { user in
                        ProfileImageSync.shared.syncProfilePhotoUrl(userId: user.id)
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func updateMember(_ member: User, actorUserId: String, displayName: String, role: String, email: String, phone: String, password: String?, profileImage: UIImage?, isOnline: Bool) {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRole = role.trimmingCharacters(in: .whitespacesAndNewlines)

        var fields: [String: Any] = [:]
        if !trimmedName.isEmpty {
            fields["displayName"] = trimmedName
        }
        if !trimmedRole.isEmpty {
            fields["role"] = trimmedRole.uppercased()
        }
        fields["email"] = email.trimmingCharacters(in: .whitespacesAndNewlines)
        fields["phone"] = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let password = password, !password.isEmpty {
            fields["password"] = password
        }

        let updated = User(
            id: member.id,
            organizationId: member.organizationId,
            username: member.username,
            displayName: trimmedName.isEmpty ? member.displayName : trimmedName,
            role: trimmedRole.isEmpty ? member.role : trimmedRole.uppercased(),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: member.latitude,
            longitude: member.longitude
        )

        localStorage.saveUsers([updated])
        members = localStorage.fetchUsers(organizationId: member.organizationId)

        guard isOnline else {
            SyncManager.shared.enqueueUserProfileUpdate(userId: member.id, organizationId: member.organizationId, actorUserId: actorUserId, fields: fields)
            return
        }
        
        let dispatchGroup = DispatchGroup()
        
        if let image = profileImage, let data = image.jpegData(compressionQuality: 0.8) {
            dispatchGroup.enter()
            ProfilePhotoService.shared.uploadProfilePhoto(data: data, userId: member.id) { _ in
                // Handled inherently by ProfilePhotoService which updates user doc
                // We'll also want to force a local cache update
                ProfileImageSync.shared.syncProfilePhotoUrl(userId: member.id)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.enter()
        firebase.updateUserProfile(userId: member.id, fields: fields) { result in
            if case .failure(let error) = result {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
            dispatchGroup.leave()
        }
    }

    func deleteMember(_ member: User, actorUserId: String, isOnline: Bool, completion: @escaping (Bool) -> Void) {
        // Remove locally immediately for snappy UI
        localStorage.deleteUser(id: member.id)
        members = localStorage.fetchUsers(organizationId: member.organizationId)

        guard isOnline else {
            SyncManager.shared.enqueueUserProfileDelete(userId: member.id, organizationId: member.organizationId, actorUserId: actorUserId)
            completion(true)
            return
        }
        firebase.deleteUserProfile(userId: member.id) { result in
            DispatchQueue.main.async {
                if case .failure(let error) = result {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
}
