import Foundation
import Combine

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

    func updateMember(_ member: User, displayName: String, role: String, email: String, phone: String, isOnline: Bool) {
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

        let updated = User(
            id: member.id,
            organizationId: member.organizationId,
            username: member.username,
            displayName: trimmedName.isEmpty ? member.displayName : trimmedName,
            role: trimmedRole.isEmpty ? member.role : trimmedRole.uppercased(),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        localStorage.saveUsers([updated])
        members = localStorage.fetchUsers(organizationId: member.organizationId)

        guard isOnline else { return }
        firebase.updateUserProfile(userId: member.id, fields: fields) { result in
            if case .failure(let error) = result {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
