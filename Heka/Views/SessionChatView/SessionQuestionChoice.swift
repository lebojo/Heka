import SwiftUI

struct SessionQuestionChoice: View {
    let option: SessionUserQuestion.Option
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            Image(systemName: symbol)
                .foregroundStyle(Color.textSecondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(verbatim: option.label).font(Font.chatChoice)
                if let detail = option.detail {
                    Text(verbatim: detail).foregroundStyle(Color.textSecondary)
                }
            }
        }
    }
}
