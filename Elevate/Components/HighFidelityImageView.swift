import SwiftUI

struct HighFidelityImageView: View {
    let urlString: String?
    let placeholderIcon: String
    var cornerRadius: CGFloat = 12
    var backgroundColor: Color? = nil
    
    @ObservedObject var settings = AccessibilitySettings.shared

    var body: some View {
        ZStack {
            if let urlString = urlString, !urlString.isEmpty {
                if urlString.hasPrefix("data:image") {
                    if let uiImage = ImageUtils.decodeBase64(urlString) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                    } else {
                        placeholder
                    }
                } else if urlString.hasPrefix("file://") {
                    if let url = URL(string: urlString),
                       let data = try? Data(contentsOf: url),
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                    } else {
                        placeholder
                    }
                } else if let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable()
                                .aspectRatio(1, contentMode: .fill)
                                .clipped()
                        case .failure:
                            placeholder
                        case .empty:
                            ProgressView()
                                .scaleEffect(0.8)
                        @unknown default:
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }
            } else {
                placeholder
            }
        }
        .aspectRatio(1, contentMode: .fit) // Enforce square container
        .background(backgroundColor ?? settings.surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var placeholder: some View {
        ZStack {
            backgroundColor ?? settings.surfaceColor
            Image(systemName: placeholderIcon)
                .font(.system(size: 20))
                .foregroundColor(settings.secondaryText.opacity(0.3))
        }
        .aspectRatio(1, contentMode: .fill)
    }
}
