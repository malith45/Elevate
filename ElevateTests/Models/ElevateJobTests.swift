import XCTest
@testable import Elevate

@MainActor
final class ElevateJobTests: XCTestCase {

    func testJobOverdueLogic() {
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let futureDate = Date().addingTimeInterval(3600) // 1 hour future
        
        var job = Job(
            id: "1", organizationId: "org", title: "Test Job", location: "Here",
            scheduledAt: pastDate, status: "PENDING", priority: "HIGH",
            isUrgent: false, isOnHold: false, assignedUserId: "u1",
            quotationItems: [], photoUrls: [], updatedAt: Date()
        )
        
        // Past date, status pending -> should be overdue
        XCTAssertTrue(job.isOverdue)
        
        // Future date -> should not be overdue
        job.scheduledAt = futureDate
        XCTAssertFalse(job.isOverdue)
        
        // Past date but completed -> should not be overdue
        job.scheduledAt = pastDate
        job.status = "COMPLETED"
        XCTAssertFalse(job.isOverdue)
        
        // Past date but cancelled -> should not be overdue
        job.status = "CANCELLED"
        XCTAssertFalse(job.isOverdue)
        
        // Past date but in-progress -> should not be overdue
        job.status = "IN-PROGRESS"
        XCTAssertFalse(job.isOverdue)
    }
}
