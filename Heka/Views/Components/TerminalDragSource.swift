import SwiftUI

struct TerminalDragSource: ViewModifier {
    @Environment(WorkspaceStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme

    let terminalID: UUID

    private var title: String { store.context(for: terminalID)?.terminal.name ?? TerminalRecord.defaultName }

    func body(content: Content) -> some View {
        content.onDrag {
            guard !store.isReadOnly else { return NSItemProvider() }
            store.beginDragging(terminalID)
            return TerminalDragItem(terminalID: terminalID).itemProvider
        } preview: {
            DragPreview(title: title, systemImage: "terminal", color: Color.textSecondary, colorScheme: colorScheme)
        }
    }
}
