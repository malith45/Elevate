import SwiftUI
import UIKit

struct PhotoPreview: View {
    let urlString: String

    var body: some View {
        if urlString.hasPrefix("file://"),
           let url = URL(string: urlString),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.elevateLightGray
            }
        } else {
            Color.elevateLightGray
        }
    }
}
