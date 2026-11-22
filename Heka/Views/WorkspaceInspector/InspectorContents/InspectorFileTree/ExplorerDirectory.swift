import SwiftUI

struct ExplorerDirectory: View {
    @State private var entries: [ExplorerEntry] = []
    @State private var omitted = 0
    @State private var error: String?
    @State private var loadedRequest: ExplorerRequest?

    let url: URL
    let refresh: Int
    let source: any InspectorSource

    private var request: ExplorerRequest { ExplorerRequest(url: url, refresh: refresh) }

    var body: some View {
        Group {
            if let error { InspectorNotice(title: "Folder Unavailable", error: error) }
            else if loadedRequest == nil { ProgressView().controlSize(.small) }
            else if entries.isEmpty { Text("Empty Folder").font(.caption).foregroundStyle(Color.textSecondary) }
            ForEach(entries) { entry in
                ExplorerRow(entry: entry, refresh: refresh, source: source)
            }
            if omitted > 0 {
                InspectorNotice(title: "Truncated List", message: "\(omitted) more items not shown on this device", symbol: "ellipsis.circle")
            }
        }
        .task(id: request, load)
    }

    private func load() async {
        let request = request
        guard loadedRequest != request else { return }
        do {
            let result = try await source.children(at: url)
            guard !Task.isCancelled else { return }
            entries = result.entries
            omitted = result.omitted
            error = nil
        } catch {
            guard !Task.isCancelled, !(error is CancellationError) else { return }
            self.error = error.localizedDescription
        }
        loadedRequest = request
    }
}
