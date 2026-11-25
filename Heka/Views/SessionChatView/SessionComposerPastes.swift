import SwiftUI

struct SessionComposerPastes: View {
    @State private var previewed: ChatPaste?

    let pastes: [ChatPaste]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.s) {
                ForEach(pastes) { paste in
                    SessionComposerPasteChip(previewed: $previewed, paste: paste)
                }
            }
            .padding(.top, Spacing.xs)
        }
        .scrollIndicators(.never)
        .sheet(item: $previewed) { paste in
            SessionPasteSheet(paste: paste)
        }
    }
}
