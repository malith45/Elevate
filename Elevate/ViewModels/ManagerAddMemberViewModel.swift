import Foundation
import Combine

final class ManagerAddMemberViewModel: ObservableObject {
    @Published var isSaving = false
    @Published var errorMessage: String?
    
    // Field-specific errors
    @Published var usernameError: String?
    @Published var displayNameError: String?
    @Published var emailError: String?
    @Published var phoneError: String?
    @Published var passwordError: String?
    @Published var confirmPasswordError: String?

    private let firebase = FirebaseService.shared
    private let localStorage = LocalStorageService.shared

    func validate(username: String, displayName: String, email: String, phone: String, password: String, confirmPassword: String) -> Bool {
        var isValid = true
        
        // Reset errors
        usernameError = nil
        displayNameError = nil
        emailError = nil
        phoneError = nil
        passwordError = nil
        confirmPasswordError = nil
        errorMessage = nil
        
        if username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            usernameError = "Username is required"
            isValid = false
        }
        
        if displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            displayNameError = "Display name is required"
            isValid = false
        }
        
        if !email.isEmpty && !isValidEmail(email) {
            emailError = "Please enter a valid email address"
            isValid = false
        }
        
        if !phone.isEmpty && !isValidPhone(phone) {
            phoneError = "Phone number contains invalid characters"
            isValid = false
        }
        
        let validation = PasswordValidator.validate(password)
        if !validation.isValid {
            passwordError = validation.message
            isValid = false
        }
        
        if password != confirmPassword {
            confirmPasswordError = "Passwords do not match"
            isValid = false
        }
        
        return isValid
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    private func isValidPhone(_ phone: String) -> Bool {
        // Allow numbers, spaces, +, -, (, )
        let phoneRegEx = "^[\\d\\s\\+\\-\\(\\)]*$"
        let phonePred = NSPredicate(format:"SELF MATCHES %@", phoneRegEx)
        return phonePred.evaluate(with: phone)
    }

    func createMember(organizationId: String, username: String, displayName: String, role: String, email: String?, phone: String?, password: String?, completion: @escaping (User?) -> Void) {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
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
