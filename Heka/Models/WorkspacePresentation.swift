import Observation
import SwiftUI

@MainActor @Observable final class WorkspacePresentation {
    var sheet: WorkspaceSheet?
    var removal: Removal?
}

extension FocusedValues {
    @Entry var workspacePresentation: WorkspacePresentation?
}
