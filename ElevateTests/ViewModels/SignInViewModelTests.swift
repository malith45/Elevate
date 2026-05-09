import XCTest
@testable import Elevate

final class SignInViewModelTests: XCTestCase {

    @MainActor
    func testSignInValidationEmptyFields() {
        let viewModel = SignInViewModel()
        
        viewModel.organizationId = ""
        viewModel.username = ""
        viewModel.password = ""
        
        viewModel.signIn(appSession: nil)
        
        XCTAssertEqual(viewModel.errorMessage, "All fields are required.")
        XCTAssertFalse(viewModel.isLoading)
    }
    
    @MainActor
    func testSignInValidationMissingPassword() {
        let viewModel = SignInViewModel()
        
        viewModel.organizationId = "org123"
        viewModel.username = "user"
        viewModel.password = ""
        
        viewModel.signIn(appSession: nil)
        
        XCTAssertEqual(viewModel.errorMessage, "All fields are required.")
        XCTAssertFalse(viewModel.isLoading)
    }
}
