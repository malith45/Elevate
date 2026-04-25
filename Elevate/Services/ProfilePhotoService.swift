import Foundation
import FirebaseFirestore

final class ProfilePhotoService {
    static let shared = ProfilePhotoService()
    
    private let firebase = FirebaseService.shared
    private let db = Firestore.firestore()

    private init() {}

    func uploadProfilePhoto(data: Data, userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let base64String = ImageUtils.compressAndEncode(data: data) else {
            completion(.failure(NSError(domain: "Image", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to process photo."])))
            return
        }
        
        self.firebase.updateUserProfile(userId: userId, fields: [
            "photoUrl": base64String
        ]) { result in
            switch result {
            case .success:
                ProfileImageStore.shared.deleteImage(for: userId) // Clear disk cache
                ProfileImageCache.shared.saveRemoteUrl(base64String, for: userId)
                NotificationCenter.default.post(name: .profilePhotoDidUpdate, object: nil, userInfo: ["userId": userId])
                completion(.success(base64String))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
