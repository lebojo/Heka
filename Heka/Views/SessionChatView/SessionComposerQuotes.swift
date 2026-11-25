import SwiftUI

struct SessionComposerQuotes: View {
    let quotes: [ChatQuote]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.s) {
                ForEach(quotes) { quote in
                    SessionComposerQuote(quote: quote)
                }
            }
            .padding(.top, Spacing.xs)
        }
        .scrollIndicators(.never)
    }
}
