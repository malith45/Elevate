import Foundation
import Combine

final class SessionStore {
    static let shared = SessionStore()

    private let userDefaults = UserDefaults.standard
    private let sessionKey = "loggedInUserId"

    func saveUserId(_ id: String) {
        userDefaults.set(id, forKey: sessionKey)
    }

    func getUserId() -> String? {
        userDefaults.string(forKey: sessionKey)
    }

    func clear() {
        userDefaults.removeObject(forKey: sessionKey)
    }
}
