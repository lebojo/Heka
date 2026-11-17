import SwiftUI

struct SessionQuestionMessage: View {
    let message: SessionMessage
    let questions: [SessionUserQuestion]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            ForEach(questions.indices, id: \.self) { index in
                SessionQuestionContent(question: questions[index])
            }
            if let answer = message.questionAnswer {
                Divider()
                Text(verbatim: answer).textSelection(.enabled)
                    .foregroundStyle(message.displayedToolState.tint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.l)
        .background(Palette.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: Radius.l))
    }
}
