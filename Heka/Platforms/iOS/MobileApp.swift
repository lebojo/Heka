import SwiftUI

@main struct MobileApp: App {
    @State private var chatDrafts = ChatDrafts()

    var body: some Scene {
        WindowGroup { MobileWorkspaceView().environment(chatDrafts) }
    }
}
