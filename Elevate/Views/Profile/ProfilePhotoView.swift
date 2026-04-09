import SwiftUI
import UIKit

struct ProfilePhotoView: View {
    let userId: String
    let size: CGFloat

    private var localImage: UIImage? {
        ProfileImageStore.shared.loadImage(for: userId)
    }

    private var remoteUrl: URL? {
        if let urlString = ProfileImageCache.shared.remoteUrl(for: userId) {
            return URL(string: urlString)
        }
        return nil
    }

    var body: some View {
        ZStack {
            if let image = localImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let remoteUrl = remoteUrl {
                AsyncImage(url: remoteUrl) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.45))
                        .foregroundColor(.white)
                }
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundColor(.white)
            }
        }
        .frame(width: size, height: size)
        .background(Color.elevateDarkGreen)
        .clipShape(Circle())
    }
}
