import Foundation
import Combine

final class SignUpViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firebase = FirebaseService.shared
    private let localStorage = LocalStorageService.shared

    func signUp(organizationName: String, organizationId: String, username: String, password: String, completion: @escaping (User?) -> Void) {
        let trimmedOrgName = organizationName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOrgId = organizationId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedOrgName.isEmpty else {
            errorMessage = "Organization name is required."
            completion(nil)
            return
        }
        guard !trimmedOrgId.isEmpty else {
            errorMessage = "Organization ID is required."
            completion(nil)
            return
        }
        guard !trimmedUsername.isEmpty else {
            errorMessage = "Username is required."
            completion(nil)
            return
        }
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            completion(nil)
            return
        }

        isLoading = true
        firebase.isOrganizationIdAvailable(trimmedOrgId) { orgResult in
            switch orgResult {
            case .failure(let error):
                DispatchQueue.main.async(execute: DispatchWorkItem(block: {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    completion(nil)
                }))
            case .success(let isAvailable):
                guard isAvailable else {
                    DispatchQueue.main.async(execute: DispatchWorkItem(block: {
                        self.isLoading = false
                        self.errorMessage = "Organization ID is already in use."
                        completion(nil)
                    }))
                    return
                }

                self.firebase.isUsernameAvailable(organizationId: trimmedOrgId, username: trimmedUsername) { userResult in
                    switch userResult {
                    case .failure(let error):
                        DispatchQueue.main.async(execute: DispatchWorkItem(block: {
                            self.isLoading = false
                            self.errorMessage = error.localizedDescription
                            completion(nil)
                        }))
                    case .success(let userAvailable):
                        guard userAvailable else {
                            DispatchQueue.main.async(execute: DispatchWorkItem(block: {
                                self.isLoading = false
                                self.errorMessage = "Username is already in use."
                                completion(nil)
                            }))
                            return
                        }

                        self.firebase.createOrganization(organizationId: trimmedOrgId, name: trimmedOrgName) { orgCreate in
                            switch orgCreate {
                            case .failure(let error):
                                DispatchQueue.main.async(execute: DispatchWorkItem(block: {
                                    self.isLoading = false
                                    self.errorMessage = error.localizedDescription
                                    completion(nil)
                                }))
                            case .success:
                                self.firebase.createUser(
                                    organizationId: trimmedOrgId,
                                    username: trimmedUsername,
                                    displayName: trimmedUsername,
                                    role: "MANAGER",
                                    password: password
                                ) { userResult in
                                    DispatchQueue.main.async(execute: DispatchWorkItem(block: {
                                        self.isLoading = false
                                        switch userResult {
                                        case .success(let user):
                                            self.localStorage.saveUser(user)
                                            completion(user)
                                        case .failure(let error):
                                            self.errorMessage = error.localizedDescription
                                            completion(nil)
                                        }
                                    }))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
