import Foundation

final class ProfileImageCache {
    static let shared = ProfileImageCache()

    private init() {}

    func saveRemoteUrl(_ url: String, for userId: String) {
        UserDefaults.standard.set(url, forKey: remoteUrlKey(for: userId))
    }

    func remoteUrl(for userId: String) -> String? {
        UserDefaults.standard.string(forKey: remoteUrlKey(for: userId))
    }

    private func remoteUrlKey(for userId: String) -> String {
        "profilePhotoUrl_\(userId)"
    }
}
