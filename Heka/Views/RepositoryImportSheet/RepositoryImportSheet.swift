import SwiftUI

struct RepositoryImportSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selection: Set<String>
    @State private var flattened = false

    let store: WorkspaceStore
    let plan: RepositoryImport

    private var total: Int { plan.repositoryPaths.count }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            Label {
                Text("Import “\(plan.destinationName)”")
            } icon: {
                Image(systemName: "square.and.arrow.down").foregroundStyle(Color.accentColor)
            }
            .font(Font.sheetTitle)
            Text("\(total) Git repositories found. Choose the ones to add: virtual folders mirror the folder structure on disk. Files stay where they are.")
                .font(Font.callout).foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Toggle(isOn: $flattened) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Import Everything at the Same Level").font(Font.label)
                    Text("A single “\(plan.destinationName)” folder, without subfolders.")
                        .font(Font.caption).foregroundStyle(Color.textSecondary)
                }
            }
            .toggleStyle(.switch)
            List {
                RepositoryImportRow(selection: $selection, item: plan.preview(flattened: flattened))
            }
            .listStyle(.bordered)
            .alternatingRowBackgrounds(.disabled)
            .frame(height: Dimension.ImportSheet.listHeight)
            if let warning = plan.warning {
                Label(warning, systemImage: "exclamationmark.triangle")
                    .font(Font.caption).foregroundStyle(Color.warning)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
            HStack {
                Text("\(selection.count) of \(total) selected")
                    .font(Font.caption).monospacedDigit().foregroundStyle(Color.textSecondary)
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Import") { submit() }
                    .keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent)
                    .disabled(selection.isEmpty || store.isImporting)
            }
        }
        .padding(Spacing.xxl)
        .frame(width: Dimension.ImportSheet.width)
    }

    init(store: WorkspaceStore, plan: RepositoryImport) {
        self.store = store
        self.plan = plan
        _selection = State(initialValue: Set(plan.repositoryPaths))
    }

    private func submit() {
        let paths = selection
        let flattened = flattened
        Task { await store.importRepositories(plan, keeping: paths, flattened: flattened) }
        dismiss()
    }
}
