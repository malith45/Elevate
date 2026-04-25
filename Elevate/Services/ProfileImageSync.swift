import Foundation

final class ProfileImageSync {
    static let shared = ProfileImageSync()

    private let firebase = FirebaseService.shared

    private init() {}

    func syncProfilePhotoUrl(userId: String) {
        firebase.fetchUserPhotoUrl(userId: userId) { result in
            if case .success(let url) = result, let url {
                let current = ProfileImageCache.shared.remoteUrl(for: userId)
                if current != url {
                    ProfileImageStore.shared.deleteImage(for: userId) // Invalidate local cache
                    ProfileImageCache.shared.saveRemoteUrl(url, for: userId)
                    NotificationCenter.default.post(name: .profilePhotoDidUpdate, object: nil, userInfo: ["userId": userId])
                }
            }
        }
    }
}
