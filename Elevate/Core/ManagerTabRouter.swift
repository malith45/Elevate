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

    func handleDeepLink(type: String, targetId: String?) {
        if type == "NOTIFICATION" || targetId == nil {
            selectedTab = .dashboard
            path = NavigationPath()
            path.append(ManagerScreen.notifications)
            return
        }

        guard let targetId = targetId else { return }
        
        switch type {
        case "JOB_STARTED", "JOB_HOLD", "JOB_COMPLETED":
            selectedJobId = targetId
            selectedTab = .dashboard
            path = NavigationPath()
            path.append(ManagerScreen.jobDetails)
        case "ISSUE_REPORTED":
            selectedJobId = targetId
            selectedTab = .dashboard
            path = NavigationPath()
            path.append(ManagerScreen.jobIssueReport)
        case "QUOTE_SUBMITTED":
            selectedJobId = targetId
            selectedTab = .dashboard
            path = NavigationPath()
            path.append(ManagerScreen.quotationApproval)
        case "CRITICAL_INVENTORY":
            selectedTab = .dashboard
            path = NavigationPath()
            path.append(ManagerScreen.inventoryManager)
        default:
            selectedTab = .dashboard
            path = NavigationPath()
            path.append(ManagerScreen.notifications)
        }
    }
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
