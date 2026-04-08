import Foundation
import Combine

final class ManagerAddMemberViewModel: ObservableObject {
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let firebase = FirebaseService.shared
    private let localStorage = LocalStorageService.shared

    func createMember(organizationId: String, username: String, role: String, password: String, completion: @escaping (User?) -> Void) {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Username is required."
            completion(nil)
            return
        }

        isSaving = true
        let displayName = trimmed
        firebase.createUser(organizationId: organizationId, username: trimmed, displayName: displayName, role: role, password: password) { result in
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
