import SwiftUI

struct InspectorFileTree: View {
    let path: String
    let refresh: Int
    let source: any InspectorSource

    var body: some View {
        List {
            ExplorerDirectory(url: URL(fileURLWithPath: path), refresh: refresh, source: source)
        }
        .listStyle(.plain)
    }
}
