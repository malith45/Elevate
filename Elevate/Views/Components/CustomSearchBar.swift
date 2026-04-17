import SwiftUI

struct CustomSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.elevateTextGray)
            TextField(placeholder, text: $text)
                .scaledFont(size: 14)
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.elevateTextGray)
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
    }
}
