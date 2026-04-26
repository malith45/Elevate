import Combine
import SwiftUI

enum TechnicianScreen: Hashable {
    case dashboard
    case jobs
    case map
    case profile
    case calendar
    case statistics
    case notifications
    case jobDetails
    case jobIssueReport
    case quotationStatus
    case inventory
    case accessibility
    case profilePhoto
}

final class TechnicianTabRouter: ObservableObject {
    static let shared = TechnicianTabRouter()
    @Published var selectedTab: TabItem = .dashboard
    @Published var path = NavigationPath()
    @Published var selectedJobId: String?
    @Published var mapFocusJobId: String?

    func handleDeepLink(type: String, targetId: String?) {
        if type == "NOTIFICATION" || targetId == nil {
            selectedTab = .dashboard
            path = NavigationPath() // Clear path to avoid nesting issues
            path.append(TechnicianScreen.notifications)
            return
        }

        guard let targetId = targetId else { return }
        
        switch type {
        case "JOB_ASSIGNED", "JOB_CANCELLED":
            selectedJobId = targetId
            selectedTab = .dashboard
            path = NavigationPath()
            path.append(TechnicianScreen.jobDetails)
        case "QUOTE_APPROVED", "QUOTE_REJECTED":
            selectedJobId = targetId
            selectedTab = .dashboard
            path = NavigationPath()
            path.append(TechnicianScreen.jobDetails)
        case "ISSUE_RESOLVED", "ISSUE_COMMENTED":
            selectedJobId = targetId
            selectedTab = .dashboard
            path = NavigationPath()
            path.append(TechnicianScreen.jobIssueReport)
        default:
            selectedTab = .dashboard
            path = NavigationPath()
            path.append(TechnicianScreen.notifications)
        }
    }

    func handleWidgetDeepLink(jobId: String) {
        selectedJobId = jobId
        selectedTab = .dashboard
        // Clear existing path and jump to details
        path = NavigationPath()
        path.append(TechnicianScreen.jobDetails)
    }
}

private struct TechnicianTabRouterKey: EnvironmentKey {
    static let defaultValue: TechnicianTabRouter = .shared
}

extension EnvironmentValues {
    var technicianTabRouter: TechnicianTabRouter {
        get { self[TechnicianTabRouterKey.self] }
        set { self[TechnicianTabRouterKey.self] = newValue }
    }
}
