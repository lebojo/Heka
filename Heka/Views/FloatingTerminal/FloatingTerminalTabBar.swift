import SwiftUI

struct FloatingTerminalTabBar: View {
    @Environment(FloatingTerminalStore.self) private var floating

    var body: some View {
        HStack(spacing: Spacing.s) {
            ScrollView(.horizontal) {
                HStack(spacing: Spacing.xs) {
                    let selectedID = floating.state.selectedTab?.id
                    ForEach(floating.state.tabs) { tab in
                        let focusedID = floating.state.focusedID(in: tab)
                        FloatingTerminalTab(tab: tab, title: floating.title(of: focusedID),
                                            directory: floating.directory(of: focusedID), isSelected: tab.id == selectedID)
                    }
                }
            }
            .scrollIndicators(.hidden)
            Button { floating.openTab() } label: { Image(systemName: "plus") }
                .help(Text("New Tab (\(ShortcutAction.newTerminal.symbols))"))
                .accessibilityLabel("New tab")
                .keyboardShortcut(.newTerminal)
            Divider().frame(height: IconSize.s)
            Button { floating.split(.horizontal) } label: { Image(systemName: "rectangle.split.2x1") }
                .help(Text("Split Right (\(ShortcutAction.splitRight.symbols))"))
                .accessibilityLabel("Split terminal right")
                .keyboardShortcut(.splitRight)
            Button { floating.split(.vertical) } label: { Image(systemName: "rectangle.split.1x2") }
                .help(Text("Split Down (\(ShortcutAction.splitDown.symbols))"))
                .accessibilityLabel("Split terminal down")
                .keyboardShortcut(.splitDown)
            Divider().frame(height: IconSize.s)
            Button("Done") { floating.isPresented = false }
        }
        .buttonStyle(.borderless)
        .font(Typography.m)
        .padding(.horizontal, Spacing.m)
        .frame(height: Dimension.FloatingTerminal.tabBarHeight)
        .background {
            Group {
                Button("Previous Tab") { floating.selectTab(offset: -1) }
                    .keyboardShortcut(.previousTab)
                Button("Next Tab") { floating.selectTab(offset: 1) }
                    .keyboardShortcut(.nextTab)
            }
            .opacity(0)
            .accessibilityHidden(true)
        }
    }
}
