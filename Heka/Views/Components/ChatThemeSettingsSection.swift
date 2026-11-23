import SwiftUI

struct ChatThemeSettingsSection: View {
    @AppStorage(ChatTheme.storageKey) private var theme = ChatTheme.system

    var body: some View {
        Section {
            Picker("Theme", selection: $theme) {
                ForEach(ChatTheme.allCases) { theme in
                    Text(theme.title).tag(theme)
                }
            }.pickerStyle(.segmented)
        } header: {
            Text("Chat Theme")
        } footer: {
            Text("System follows the light or dark appearance of the device. OLED is dark with a pure black background.")
        }
    }
}
