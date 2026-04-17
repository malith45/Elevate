import Foundation
import Combine

final class ManagerAddMemberViewModel: ObservableObject {
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let firebase = FirebaseService.shared
    private let localStorage = LocalStorageService.shared

    func createMember(organizationId: String, username: String, displayName: String, role: String, email: String?, phone: String?, password: String?, completion: @escaping (User?) -> Void) {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Username is required."
            completion(nil)
            return
        }

        isSaving = true
        firebase.createUser(organizationId: organizationId, username: trimmed, displayName: displayName, role: role, email: email, phone: phone, password: password) { result in
            DispatchQueue.main.async {
                self.isSaving = false
                switch result {
                case .success(let user):
                    self.localStorage.saveUser(user)
                    completion(user)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(nil)
                }
            }
        }
    }
}
