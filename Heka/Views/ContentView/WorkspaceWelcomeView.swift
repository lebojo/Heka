import SwiftUI

struct WorkspaceWelcomeView: View {
    @Environment(WorkspaceStore.self) private var store
    @Environment(WorkspacePresentation.self) private var presentation

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "terminal").font(Font.heroSymbol).foregroundStyle(Color.textSecondary)
            Text("A home for your projects").font(Font.display)
            Text("Group your projects, open terminals\nand work on several branches at once.")
                .font(Font.l).foregroundStyle(Color.textSecondary).multilineTextAlignment(.center).lineSpacing(Spacing.xs)
            HStack(spacing: Spacing.l) {
                Button("Add Project…") { store.chooseProjects() }.buttonStyle(.borderedProminent)
                Button("Import Folder…") { store.chooseFolder() }
            }
            .padding(.top, Spacing.s)
            .disabled(!store.canImport)
            Button("Create a Virtual Folder") { presentation.sheet = .folder(parentID: nil) }.buttonStyle(.link).font(Font.m)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surface)
        .navigationTitle("Heka")
    }
}
