import SwiftUI

struct NewVirtualFolderCommand: Commands {
    @FocusedValue(\.workspacePresentation) private var presentation

    let isDisabled: Bool

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Virtual Folder…") { presentation?.sheet = .folder(parentID: nil) }
                .keyboardShortcut(.newVirtualFolder)
                .disabled(isDisabled || presentation == nil)
        }
    }
}
