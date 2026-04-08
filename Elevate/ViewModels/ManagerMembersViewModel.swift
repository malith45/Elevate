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
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
