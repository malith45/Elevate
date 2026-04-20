import Foundation
import Combine

final class ManagerOrganizationViewModel: ObservableObject {
    @Published var organizationName = ""
    @Published var introduction = ""
    @Published var errorMessage: String?

    private let firebase = FirebaseService.shared
    private let cache = UserDefaults.standard

    func load(organizationId: String, isOnline: Bool) {
        loadCached(organizationId: organizationId)
        guard isOnline else { return }
        firebase.fetchOrganization(organizationId: organizationId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let org):
                    self.organizationName = org.name
                    self.introduction = org.introduction ?? ""
                    self.saveCached(organizationId: organizationId, name: org.name, introduction: org.introduction ?? "")
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
                } else {
                    self.saveCached(organizationId: organizationId, name: name ?? self.organizationName, introduction: introduction ?? self.introduction)
                }
            }
        }
    }

    private func loadCached(organizationId: String) {
        let nameKey = "orgName_\(organizationId)"
        let introKey = "orgIntro_\(organizationId)"
        if let cachedName = cache.string(forKey: nameKey) {
            organizationName = cachedName
        }
        if let cachedIntro = cache.string(forKey: introKey) {
            introduction = cachedIntro
        }
    }

    private func saveCached(organizationId: String, name: String, introduction: String) {
        let nameKey = "orgName_\(organizationId)"
        let introKey = "orgIntro_\(organizationId)"
        cache.set(name, forKey: nameKey)
        cache.set(introduction, forKey: introKey)
    }
}
