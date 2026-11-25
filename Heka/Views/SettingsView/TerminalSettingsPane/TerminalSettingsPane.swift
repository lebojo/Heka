import SwiftUI

struct TerminalSettingsPane: View {
    @AppStorage("sessionDisplayMode") private var displayMode: SessionDisplayMode = .terminal

    @Environment(SettingsStore.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            SessionDisplaySettingsSection(mode: $displayMode)
            ChatThemeSettingsSection()
            BorderBeamSettingsSection()
            Section("Theme") {
                TerminalPreview(appearance: settings.terminal)
                TerminalThemeGrid(appearance: $settings.terminal)
            }
            TerminalFontSection(appearance: $settings.terminal)
            Section("Cursor") {
                Picker("Shape", selection: $settings.terminal.cursorShape) {
                    ForEach(TerminalCursorShape.allCases) { shape in
                        Text(shape.title).tag(shape)
                    }
                }
                .pickerStyle(.segmented)
                Toggle("Blinking", isOn: $settings.terminal.cursorBlinks)
            }
            TerminalKeyboardSettingsSection()
            Section {
                TerminalPaletteEditor(appearance: $settings.terminal)
            } header: {
                Text("Colors")
            } footer: {
                if !settings.terminal.isEditable {
                    Text("The System theme follows macOS light or dark mode. Choose another theme to edit its colors.")
                        .font(.caption).foregroundStyle(Color.textSecondary)
                }
            }
            Section {
                HStack {
                    Spacer()
                    Button("Reset") { settings.terminal = TerminalAppearance() }
                        .disabled(settings.terminal == TerminalAppearance())
                }
            }
        }
        .formStyle(.grouped)
    }
}
