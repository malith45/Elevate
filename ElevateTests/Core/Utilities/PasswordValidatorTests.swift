import XCTest
@testable import Elevate

@MainActor
final class PasswordValidatorTests: XCTestCase {

    func testPasswordLength() {
        let (isValid, message) = PasswordValidator.validate("Short1!")
        XCTAssertFalse(isValid)
        XCTAssertEqual(message, "Password must be at least 8 characters.")
    }

    func testMissingUppercase() {
        let (isValid, message) = PasswordValidator.validate("lowercase1!")
        XCTAssertFalse(isValid)
        XCTAssertEqual(message, "Include at least one uppercase letter.")
    }

    func testMissingLowercase() {
        let (isValid, message) = PasswordValidator.validate("UPPERCASE1!")
        XCTAssertFalse(isValid)
        XCTAssertEqual(message, "Include at least one lowercase letter.")
    }

    func testMissingDigit() {
        let (isValid, message) = PasswordValidator.validate("NoDigitsHere!")
        XCTAssertFalse(isValid)
        XCTAssertEqual(message, "Include at least one digit.")
    }

    func testMissingSpecialCharacter() {
        let (isValid, message) = PasswordValidator.validate("NoSpecial123")
        XCTAssertFalse(isValid)
        XCTAssertEqual(message, "Include at least one special character.")
    }

    func testValidPassword() {
        let (isValid, message) = PasswordValidator.validate("ValidP@ssw0rd")
        XCTAssertTrue(isValid)
        XCTAssertNil(message)
    }
}
