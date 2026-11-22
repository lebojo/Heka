import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            Tab("General", systemImage: "gearshape") { GeneralSettingsPane() }
            Tab("Display", systemImage: "rectangle.split.2x1") { TerminalSettingsPane() }
            Tab("Agents", systemImage: "sparkles") { AgentSettingsPane() }
            Tab("Prompts", systemImage: "text.bubble") { PromptSettingsPane() }
            Tab("Shortcuts", systemImage: "keyboard") { ShortcutSettingsPane() }
            Tab("Mobile Control", systemImage: "iphone") { HostSettingsPane() }
        }
        .frame(width: Dimension.Settings.width)
        .frame(minHeight: Dimension.Settings.minHeight, idealHeight: Dimension.Settings.idealHeight)
    }
}
