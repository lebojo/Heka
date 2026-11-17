import SwiftUI

struct OnboardingProjectPage: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(WorkspaceStore.self) private var store

    private var isDisabled: Bool { store.isReadOnly || store.isImporting }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingPageHeader(title: "Your First Project", subtitle: "Add a Git repository, or import a folder that contains several of them.")
            HStack(spacing: 12) {
                Button {
                    dismiss()
                    store.chooseProjects()
                } label: {
                    Label("Add Project…", systemImage: "plus.rectangle.on.folder")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut("o")
                Button {
                    dismiss()
                    store.chooseFolder()
                } label: {
                    Label("Import Folder…", systemImage: "square.and.arrow.down.on.square")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }
            .controlSize(.large)
            .disabled(isDisabled)
            Text("You can do this later from the File menu.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}
