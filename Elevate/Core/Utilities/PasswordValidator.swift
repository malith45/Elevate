import Foundation

struct PasswordValidator {
    static func validate(_ password: String) -> (isValid: Bool, message: String?) {
        if password.count < 8 {
            return (false, "Password must be at least 8 characters.")
        }
        
        let uppercaseRegEx  = ".*[A-Z]+.*"
        let uppercaseTest = NSPredicate(format:"SELF MATCHES %@", uppercaseRegEx)
        if !uppercaseTest.evaluate(with: password) {
            return (false, "Include at least one uppercase letter.")
        }
        
        let lowercaseRegEx  = ".*[a-z]+.*"
        let lowercaseTest = NSPredicate(format:"SELF MATCHES %@", lowercaseRegEx)
        if !lowercaseTest.evaluate(with: password) {
            return (false, "Include at least one lowercase letter.")
        }
        
        let numberRegEx  = ".*[0-9]+.*"
        let numberTest = NSPredicate(format:"SELF MATCHES %@", numberRegEx)
        if !numberTest.evaluate(with: password) {
            return (false, "Include at least one digit.")
        }
        
        let specialCharacterRegEx  = ".*[!@#$%^&*()\\-_=+{}|;:'\",.<>/?].*"
        let specialCharacterTest = NSPredicate(format:"SELF MATCHES %@", specialCharacterRegEx)
        if !specialCharacterTest.evaluate(with: password) {
            return (false, "Include at least one special character.")
        }
        
        return (true, nil)
    }
}
