import SwiftUI

struct DiffBanner: View {
    let line: GitDiffLine

    var body: some View {
        Text(line.text)
            .font(.code).foregroundStyle(Color.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.m).padding(.vertical, Spacing.xs)
            .background(line.kind.background)
    }
}
