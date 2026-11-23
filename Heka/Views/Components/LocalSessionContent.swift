import SwiftUI

struct LocalSessionContent: View {
    @AppStorage("sessionDisplayMode") private var displayMode: SessionDisplayMode = .terminal

    @Environment(SettingsStore.self) private var settings
    @Environment(InstalledAgents.self) private var installedAgents

    @State private var launchError: String?

    let session: TerminalSession
    let isFocused: Bool
    let focus: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if displayMode == .chat, session.agent != nil {
                LocalSessionChat(session: session)
                    .simultaneousGesture(TapGesture().onEnded { focus() })
                    .overlay(alignment: .topTrailing) { RemoteGridBadge(session: session) }
            } else {
                NativeTerminalView(session: session, appearance: settings.terminal, isFocused: isFocused) { focus() }
                    .id(ObjectIdentifier(session))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .topTrailing) { RemoteGridBadge(session: session) }
                if displayMode == .chat, !session.hasExited, !installedAgents.agents.isEmpty {
                    AgentShortcutBar(agents: installedAgents.agents) { agent in launch(agent) }
                        .disabled(session.isLaunchingAgent)
                }
            }
        }
        .alert("Couldn’t Complete the Operation", isPresented: $launchError.isPresent) {
            Button("OK") { launchError = nil }
        } message: { Text(launchError ?? "") }
    }

    private func launch(_ agent: ConversationAgent) {
        focus()
        Task {
            do { try await session.launch(agent, skippingPermissions: settings.agentLaunch.skipsPermissions, from: .local) }
            catch { launchError = error.localizedDescription }
        }
    }
}
