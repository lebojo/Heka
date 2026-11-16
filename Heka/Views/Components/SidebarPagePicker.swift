import SwiftUI

struct SidebarPagePicker: View {
    @Binding var page: SidebarPage

    var body: some View {
        Picker("Sidebar Page", selection: $page) {
            ForEach(SidebarPage.allCases) { page in
                Label(page.title, systemImage: page.systemImage).tag(page)
            }
        }
        .pickerStyle(.segmented)
        .labelStyle(.iconOnly)
        .help("Sidebar Page")
    }
}
