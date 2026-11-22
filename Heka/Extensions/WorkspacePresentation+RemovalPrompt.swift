import Foundation

extension WorkspacePresentation {
    subscript(presenting prompt: RemovalPrompt?) -> Bool {
        get { prompt.map { $0.removal == removal } ?? false }
        set { if !newValue { removal = nil } }
    }
}
