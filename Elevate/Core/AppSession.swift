import Foundation
import Combine

final class AppSession: ObservableObject {
    @Published private(set) var currentUser: User?

    private let sessionStore = SessionStore.shared
    private let localStorage = LocalStorageService.shared

    init() {
        if let userId = sessionStore.getUserId(), let user = localStorage.fetchUser(id: userId) {
            currentUser = user
            if let token = NotificationService.shared.notificationToken() {
                FirebaseService.shared.saveFcmToken(userId: user.id, token: token)
            }
        }
    }

    func signIn(user: User) {
        sessionStore.saveUserId(user.id)
        currentUser = user
        if let token = NotificationService.shared.notificationToken() {
            FirebaseService.shared.saveFcmToken(userId: user.id, token: token)
        }
    }

    func signOut() {
        sessionStore.clear()
        currentUser = nil
    }
}
