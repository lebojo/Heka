import SwiftUI

struct MobileSessionDetail: View {
    @Binding var settingsVisible: Bool

    let mode: SessionDisplayMode
    let store: MobileWorkspaceStore

    var body: some View {
        Group {
            if let context = store.context {
                VStack(spacing: 0) {
                    MobileSessionHeader(project: context.project.name, worktree: context.worktree.name,
                                        agent: store.terminalSummary(context.terminal.id)?.agent)
                    Divider()
                    if let session = store.session {
                        MobileSessionContent(mode: mode, context: context, session: session, store: store)
                    } else {
                        ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    if !store.isConnected {
                        Button(store.statusText) { settingsVisible = true }.font(Font.caption).padding()
                    }
                }
                .navigationTitle(context.terminal.name)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Settings", systemImage: "gearshape") { settingsVisible = true }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("New Terminal", systemImage: "plus") { Task { await store.newTerminal(in: context) } }
                            .disabled(!store.isConnected)
                    }
                }
            } else {
                MobileSessionPlaceholder(settingsVisible: $settingsVisible, isConnected: store.isConnected)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
