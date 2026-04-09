import Foundation
import UIKit

final class ProfileImageStore {
    static let shared = ProfileImageStore()

    private init() {}

    func saveImage(_ data: Data, for userId: String) -> URL? {
        let fileURL = imageURL(for: userId)
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: fileURL, options: [.atomic])
            return fileURL
        } catch {
            return nil
        }
    }

    func imageURL(for userId: String) -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return directory.appendingPathComponent("ProfileImages", isDirectory: true)
            .appendingPathComponent("\(userId).jpg")
    }

    func loadImage(for userId: String) -> UIImage? {
        let url = imageURL(for: userId)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
