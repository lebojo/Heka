import SwiftUI

struct DiffStats: View {
    let additions: Int
    let deletions: Int

    var body: some View {
        HStack(spacing: Spacing.s) {
            Text("+\(additions)").foregroundStyle(Color.success)
            Text("−\(deletions)").foregroundStyle(Color.danger)
        }
        .font(.captionMono)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(additions) additions, \(deletions) deletions")
    }
}
