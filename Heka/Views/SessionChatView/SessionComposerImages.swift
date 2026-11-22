import SwiftUI

struct SessionComposerImages: View {
    let images: [URL]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.s) {
                ForEach(images, id: \.self) { image in
                    SessionComposerThumbnail(image: image)
                }
            }
            .padding(.top, Spacing.xs)
        }
        .scrollIndicators(.never)
    }
}
