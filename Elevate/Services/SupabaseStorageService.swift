import Foundation

final class SupabaseStorageService {
    static let shared = SupabaseStorageService()

    private let baseURL: URL
    private let anonKey: String
    private let bucket: String

    private init() {
        guard let configUrl = Bundle.main.url(forResource: "SupabaseConfig", withExtension: "plist"),
              let data = try? Data(contentsOf: configUrl),
              let raw = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let dict = raw as? [String: Any],
              let urlString = dict["SupabaseURL"] as? String,
              let anonKey = dict["SupabaseAnonKey"] as? String,
              let bucket = dict["SupabaseBucket"] as? String,
              let baseURL = URL(string: urlString)
        else {
            fatalError("SupabaseConfig.plist is missing or invalid.")
        }

        self.baseURL = baseURL
        self.anonKey = anonKey
        self.bucket = bucket
    }

    func uploadPublicFile(data: Data, path: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let uploadURL = makeStorageURL(path: "storage/v1/object", objectPath: path) else {
            completion(.failure(SupabaseStorageError.invalidURL))
            return
        }

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("true", forHTTPHeaderField: "x-upsert")

        URLSession.shared.uploadTask(with: request, from: data) { [weak self] _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion(.failure(SupabaseStorageError.invalidResponse))
                return
            }

            guard (200...299).contains(http.statusCode) else {
                completion(.failure(SupabaseStorageError.requestFailed(status: http.statusCode)))
                return
            }

            guard let self = self,
                  let publicURL = self.makeStorageURL(path: "storage/v1/object/public", objectPath: path)
            else {
                completion(.failure(SupabaseStorageError.invalidURL))
                return
            }

            completion(.success(publicURL.absoluteString))
        }.resume()
    }

    private func makeStorageURL(path: String, objectPath: String) -> URL? {
        var url = baseURL
        let pathComponents = path.split(separator: "/").map(String.init)
        pathComponents.forEach { url.appendPathComponent($0) }
        url.appendPathComponent(bucket)

        let objectComponents = objectPath.split(separator: "/").map(String.init)
        objectComponents.forEach { url.appendPathComponent($0) }
        return url
    }
}

enum SupabaseStorageError: Error {
    case invalidURL
    case invalidResponse
    case requestFailed(status: Int)
}
