import SwiftUI

struct SessionQuestionContent: View {
    let question: SessionUserQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            if let heading = question.heading {
                Text(verbatim: heading).font(Typography.caption).foregroundStyle(Palette.textSecondary)
            }
            Text(verbatim: question.question).font(Typography.chatQuestion)
            ForEach(question.choices.indices, id: \.self) { index in
                SessionQuestionChoice(option: question.choices[index], symbol: question.choiceSymbol)
            }
        }
        .textSelection(.enabled)
        .fixedSize(horizontal: false, vertical: true)
    }
}
