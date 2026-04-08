import Foundation
import Combine

final class ManagerOrganizationViewModel: ObservableObject {
    @Published var organizationName = ""
    @Published var introduction = ""
    @Published var errorMessage: String?

    private let firebase = FirebaseService.shared

    func load(organizationId: String, isOnline: Bool) {
        guard isOnline else { return }
        firebase.fetchOrganization(organizationId: organizationId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let org):
                    self.organizationName = org.name
                    self.introduction = org.introduction ?? ""
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func save(organizationId: String, name: String?, introduction: String?) {
        firebase.updateOrganization(organizationId: organizationId, name: name, introduction: introduction) { result in
            DispatchQueue.main.async {
                if case .failure(let error) = result {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
