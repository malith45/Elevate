import Foundation
import Combine

final class SessionStore {
    static let shared = SessionStore()

    private let userDefaults = UserDefaults.standard
    private let sessionKey = "loggedInUserId"
    private let biometricKey = "lastBiometricUserId"

    func saveUserId(_ id: String) {
        userDefaults.set(id, forKey: sessionKey)
        userDefaults.set(id, forKey: biometricKey)
    }

    func getUserId() -> String? {
        userDefaults.string(forKey: sessionKey)
    }

    func getLastBiometricUserId() -> String? {
        userDefaults.string(forKey: biometricKey)
    }

    func clear() {
        userDefaults.removeObject(forKey: sessionKey)
        // Intentionally do not clear biometricKey to support Face ID unlock after logout
    }
}
