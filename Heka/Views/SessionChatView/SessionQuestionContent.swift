import SwiftUI

struct SessionQuestionContent: View {
    let question: SessionUserQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            if let heading = question.heading {
                Text(verbatim: heading).font(Font.caption).foregroundStyle(Color.textSecondary)
            }
            Text(verbatim: question.question).font(Font.chatQuestion)
            ForEach(question.choices) { option in
                SessionQuestionChoice(option: option, symbol: question.choiceSymbol)
            }
        }
        .textSelection(.enabled)
        .fixedSize(horizontal: false, vertical: true)
    }
}
