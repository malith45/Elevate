import Foundation

extension ProfileImageStore {
    func saveRemoteUrl(_ url: String, for userId: String) {
        ProfileImageCache.shared.saveRemoteUrl(url, for: userId)
    }

    func remoteUrl(for userId: String) -> String? {
        ProfileImageCache.shared.remoteUrl(for: userId)
    }
}
