import SwiftUI

struct SessionComposerImages: View {
    @Binding var images: [URL]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.s) {
                ForEach(images, id: \.self) { image in
                    thumbnail(image)
                }
            }
            .padding(.top, Spacing.xs)
        }
        .scrollIndicators(.never)
    }

    private func thumbnail(_ image: URL) -> some View {
        AsyncImage(url: image) { picture in
            picture.resizable().scaledToFill()
        } placeholder: {
            Palette.textTertiary.opacity(0.2)
        }
        .frame(width: Dimension.Chat.attachmentSize, height: Dimension.Chat.attachmentSize)
        .clipShape(.rect(cornerRadius: Radius.m))
        .overlay(alignment: .topTrailing) {
            Button { images.removeAll { $0 == image } } label: {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.6))
            }
            .buttonStyle(.plain)
            .padding(Spacing.xxs)
            .accessibilityLabel("Remove Image")
            .help("Remove Image")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Attached Image")
    }
}
