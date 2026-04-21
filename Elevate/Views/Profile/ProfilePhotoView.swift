import SwiftUI
import UIKit


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
            } else {
                HighFidelityImageView(urlString: remoteUrlString, placeholderIcon: "person.fill", cornerRadius: size / 2, backgroundColor: Color.elevateDarkGreen)
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


    private func reloadImage() {
        localImage = ProfileImageStore.shared.loadImage(for: userId)
        remoteUrlString = ProfileImageCache.shared.remoteUrl(for: userId)
    }
}
