import Foundation
import Combine

final class ManagerEditProfileViewModel: ObservableObject {
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let firebase = FirebaseService.shared

    func updateProfile(user: User, username: String, displayName: String, email: String, phone: String, password: String?, completion: @escaping (User?) -> Void) {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            errorMessage = "Username is required."
            completion(nil)
            return
        }

        var fields: [String: Any] = [
            "username": trimmed,
            "displayName": trimmedDisplayName.isEmpty ? trimmed : trimmedDisplayName,
            "email": trimmedEmail,
            "phone": trimmedPhone
        ]
        if let password = password, !password.isEmpty {
            fields["password"] = password
        }

        isSaving = true
        firebase.updateUserProfile(userId: user.id, fields: fields) { result in
            DispatchQueue.main.async(execute: DispatchWorkItem(block: {
                self.isSaving = false
                switch result {
                case .success:
                    let updated = User(
                        id: user.id,
                        organizationId: user.organizationId,
                        username: trimmed,
                        displayName: trimmedDisplayName.isEmpty ? trimmed : trimmedDisplayName,
                        role: user.role,
                        email: trimmedEmail.isEmpty ? nil : trimmedEmail,
                        phone: trimmedPhone.isEmpty ? nil : trimmedPhone
                    )
                    completion(updated)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(nil)
                }
            }))
        }
    }

    func dropOrganization(organizationId: String, appSession: AppSession, completion: @escaping (Bool) -> Void) {
        isSaving = true
        firebase.dropOrganization(organizationId: organizationId) { result in
            DispatchQueue.main.async {
                self.isSaving = false
                switch result {
                case .success:
                    appSession.signOut()
                    completion(true)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }

    func deleteProfile(userId: String, appSession: AppSession, completion: @escaping (Bool) -> Void) {
        isSaving = true
        firebase.deleteUserProfile(userId: userId) { result in
            DispatchQueue.main.async {
                self.isSaving = false
                switch result {
                case .success:
                    appSession.signOut()
                    completion(true)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
}
