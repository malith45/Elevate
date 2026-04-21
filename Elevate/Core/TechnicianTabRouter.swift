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
