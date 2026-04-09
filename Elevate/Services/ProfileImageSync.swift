import Foundation

final class ProfileImageSync {
    static let shared = ProfileImageSync()

    private let firebase = FirebaseService.shared

    private init() {}

    func syncProfilePhotoUrl(userId: String) {
        firebase.fetchUserPhotoUrl(userId: userId) { result in
            if case .success(let url) = result, let url {
                ProfileImageCache.shared.saveRemoteUrl(url, for: userId)
            }
        }
    }
}
