import Foundation

extension Notification.Name {
    /// Posted when a profile photo is updated (either successfully uploaded or synced).
    /// userInfo: ["userId": String]
    static let profilePhotoDidUpdate = Notification.Name("profilePhotoDidUpdate")
}
