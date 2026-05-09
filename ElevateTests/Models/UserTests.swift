import XCTest
@testable import Elevate

@MainActor
final class UserTests: XCTestCase {

    func testUserInitialization() {
        let user = User(
            id: "123",
            organizationId: "org-456",
            username: "testuser",
            displayName: "Test User",
            role: "Technician",
            email: "test@example.com",
            phone: "+1234567890",
            latitude: 37.7749,
            longitude: -122.4194,
            notificationsEnabled: true
        )
        
        XCTAssertEqual(user.id, "123")
        XCTAssertEqual(user.organizationId, "org-456")
        XCTAssertEqual(user.username, "testuser")
        XCTAssertEqual(user.displayName, "Test User")
        XCTAssertEqual(user.role, "Technician")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.phone, "+1234567890")
        XCTAssertEqual(user.latitude, 37.7749)
        XCTAssertEqual(user.longitude, -122.4194)
        XCTAssertTrue(user.notificationsEnabled)
    }

    func testUserEncodingDecoding() throws {
        let originalUser = User(
            id: "123",
            organizationId: "org-456",
            username: "testuser",
            displayName: "Test User",
            role: "Manager",
            email: nil,
            phone: nil,
            latitude: nil,
            longitude: nil,
            notificationsEnabled: false
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalUser)
        
        let decoder = JSONDecoder()
        let decodedUser = try decoder.decode(User.self, from: data)
        
        XCTAssertEqual(originalUser, decodedUser)
    }
}
