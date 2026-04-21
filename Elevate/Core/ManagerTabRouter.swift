import Combine
import SwiftUI

enum ManagerScreen {
    case dashboard
    case calendar
    case statistics
    case notifications
    case jobs
    case map
    case profile
    case accessibility
    case organization
    case members
    case editProfile
    case addMember
    case jobDetails
    case jobIssueReport
    case quotationApproval
    case inventoryManager
    case createJob
    case memberDetails
    case pendingQuotations
}

final class ManagerTabRouter: ObservableObject {
    static let shared = ManagerTabRouter()
    @Published var selectedTab: TabItem = .dashboard
    @Published var currentScreen: ManagerScreen = .dashboard
    @Published var path = NavigationPath()
    @Published var selectedJobId: String?
    @Published var selectedMemberId: String?
}

private struct ManagerTabRouterKey: EnvironmentKey {
    static let defaultValue: ManagerTabRouter = .shared
}

extension EnvironmentValues {
    var managerTabRouter: ManagerTabRouter {
        get { self[ManagerTabRouterKey.self] }
        set { self[ManagerTabRouterKey.self] = newValue }
    }
}
