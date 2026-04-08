import Foundation
import Combine

final class ManagerEditProfileViewModel: ObservableObject {
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let firebase = FirebaseService.shared

    func updateProfile(user: User, username: String, password: String?, completion: @escaping (User?) -> Void) {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Username is required."
            completion(nil)
            return
        }

        var fields: [String: Any] = [
            "username": trimmed,
            "displayName": trimmed
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
                        displayName: trimmed,
                        role: user.role,
                        email: user.email,
                        phone: user.phone
                    )
                    completion(updated)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(nil)
                }
            }))
        }
    }
}
