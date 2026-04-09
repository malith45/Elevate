import Foundation

final class ProfilePhotoService {
    static let shared = ProfilePhotoService()

    private let supabase = SupabaseStorageService.shared
    private let firebase = FirebaseService.shared

    private init() {}

    func uploadProfilePhoto(data: Data, userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let path = "profilePhotos/\(userId).jpg"
        supabase.uploadPublicFile(data: data, path: path) { result in
            switch result {
            case .success(let urlString):
                self.firebase.updateUserProfile(userId: userId, fields: [
                    "photoUrl": urlString
                ]) { updateResult in
                    switch updateResult {
                    case .success:
                        completion(.success(urlString))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
