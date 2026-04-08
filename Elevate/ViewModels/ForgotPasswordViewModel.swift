import Foundation
import Combine

final class ForgotPasswordViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let firebase = FirebaseService.shared

    func sendReset(organizationId: String?, identification: String) {
        errorMessage = nil
        successMessage = nil
        isLoading = true

        firebase.requestPasswordReset(organizationId: organizationId, identification: identification) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success:
                    self.successMessage = "Recovery request sent. Check your email or contact your administrator."
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
