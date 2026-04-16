import SwiftUI
import UIKit

// Posted after a profile photo is saved locally so ProfilePhotoView can refresh.
extension Notification.Name {
    static let profilePhotoDidUpdate = Notification.Name("profilePhotoDidUpdate")
}

struct ProfilePhotoView: View {
    let userId: String
    let size: CGFloat

    @State private var localImage: UIImage? = nil
    @State private var remoteUrlString: String? = nil
    @State private var refreshToken: UUID = UUID()

    var body: some View {
        ZStack {
            if let image = localImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let urlStr = remoteUrlString, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholderIcon
                    }
                }
            } else {
                placeholderIcon
            }
        }
        .frame(width: size, height: size)
        .background(Color.elevateDarkGreen)
        .clipShape(Circle())
        .id(refreshToken)
        .onAppear {
            reloadImage()
        }
        .onReceive(NotificationCenter.default.publisher(for: .profilePhotoDidUpdate)) { notification in
            if let uid = notification.userInfo?["userId"] as? String, uid == userId {
                reloadImage()
                refreshToken = UUID()
            }
        }
    }

    private var placeholderIcon: some View {
        Image(systemName: "person.fill")
            .font(.system(size: size * 0.45))
            .foregroundColor(.white)
    }

    private func reloadImage() {
        localImage = ProfileImageStore.shared.loadImage(for: userId)
        remoteUrlString = ProfileImageCache.shared.remoteUrl(for: userId)
    }
}
