import SwiftUI

struct DiffPreviewSheet: View {
    @AppStorage("diffLayout") private var layout: DiffLayout = .unified
    @AppStorage("diffIntraLineHighlight") private var highlightsChanges = true

    @Environment(\.dismiss) private var dismiss

    let diff: GitDiff

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.l) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(diff.path).font(.headline).lineLimit(1).truncationMode(.middle).help(diff.path)
                    if let section = diff.onlySection {
                        DiffStats(additions: section.additions, deletions: section.deletions)
                    }
                }
                Spacer()
                Toggle(isOn: $highlightsChanges) {
                    Label("Highlight Changes", systemImage: "highlighter")
                }
                .toggleStyle(.button).labelStyle(.iconOnly)
                .help("Highlight the changed parts of each line")
                Picker("Diff Layout", selection: $layout) {
                    ForEach(DiffLayout.allCases) { item in
                        Label(item.title, systemImage: item.symbol).tag(item)
                    }
                }
                .pickerStyle(.segmented).labelsHidden().fixedSize()
                Button("Close") { dismiss() }.keyboardShortcut(.cancelAction)
            }.padding()
            Divider()
            if diff.sections.isEmpty {
                ContentUnavailableView("No Diff", systemImage: "doc.text.magnifyingglass",
                                       description: Text("No diff available for this file."))
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                        ForEach(diff.sections) { section in
                            Section {
                                DiffSectionRows(section: section, layout: layout, digits: diff.lineNumberDigits,
                                                highlightsChanges: highlightsChanges)
                            } header: {
                                DiffSectionHeader(section: section)
                            }
                        }
                    }.textSelection(.enabled)
                }.background(Color.surface)
            }
        }
        .previewSheetFrame(.diff)
    }
}
