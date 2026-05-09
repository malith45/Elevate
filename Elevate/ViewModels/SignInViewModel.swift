import Foundation
import Combine

final class SignInViewModel: ObservableObject {
    @Published var organizationId = ""
    @Published var username = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firebase = FirebaseService.shared
    private let localStorage = LocalStorageService.shared

    func signIn(appSession: AppSession?) {
        errorMessage = nil
        guard !organizationId.isEmpty, !username.isEmpty, !password.isEmpty else {
            errorMessage = "All fields are required."
            return
        }

        isLoading = true
        firebase.signIn(organizationId: organizationId, username: username, password: password) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                switch result {
                case .success(let user):
                    self.localStorage.saveUser(user)
                    appSession?.signIn(user: user)
                    SyncManager.shared.startSyncing(organizationId: user.organizationId, userId: user.id, role: user.role)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
