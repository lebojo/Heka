import SwiftUI

struct NewVirtualFolderCommand: Commands {
    @FocusedValue(\.workspacePresentation) private var presentation

    let isDisabled: Bool

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Virtual Folder…") { presentation?.sheet = .folder(parentID: nil) }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                .disabled(isDisabled || presentation == nil)
        }
    }
}
