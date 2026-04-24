import Foundation
import Combine

final class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var organizationName: String = ""
    @Published var organizationCode: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firebase = FirebaseService.shared

    func load(userId: String) {
        isLoading = true
        errorMessage = nil

        firebase.fetchUser(userId: userId) { [weak self] result in
            switch result {
            case .success(let user):
                DispatchQueue.main.async {
                    self?.user = user
                    self?.organizationCode = user.organizationId
                }
                ProfileImageSync.shared.syncProfilePhotoUrl(userId: user.id)
                self?.loadOrganization(organizationId: user.organizationId)
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func loadOrganization(organizationId: String) {
        firebase.fetchOrganization(organizationId: organizationId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let org):
                    self?.organizationName = org.name
                case .failure:
                    self?.organizationName = ""
                }
            }
        }
    }

    func updateNotificationPreference(userId: String, enabled: Bool) {
        firebase.updateUserProfile(userId: userId, fields: ["notificationsEnabled": enabled]) { _ in
            // Refresh local user if needed
        }
    }
}
