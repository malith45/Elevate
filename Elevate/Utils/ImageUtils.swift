import UIKit

struct ImageUtils {
    static func compressAndEncode(data: Data, maxSize: CGFloat = 300) -> String? {
        guard let uiImage = UIImage(data: data) else { return nil }
        
        let scale = min(maxSize / uiImage.size.width, maxSize / uiImage.size.height, 1.0)
        let newSize = CGSize(width: uiImage.size.width * scale, height: uiImage.size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        uiImage.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let compressedData = resizedImage?.jpegData(compressionQuality: 0.6) else { return nil }
        return "data:image/jpeg;base64," + compressedData.base64EncodedString()
    }
    
    static func decodeBase64(_ base64String: String) -> UIImage? {
        let components = base64String.components(separatedBy: ",")
        let cleanString = components.count > 1 ? components[1] : components[0]
        guard let data = Data(base64Encoded: cleanString) else { return nil }
        return UIImage(data: data)
    }
}
