import SwiftUI

struct PhotoPreview: View {
    let urlString: String
    var placeholderIcon: String = "photo"

    var body: some View {
        HighFidelityImageView(urlString: urlString, placeholderIcon: placeholderIcon)
    }
}
