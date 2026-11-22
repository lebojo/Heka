import UIKit
import SwiftTerm

final class MobileMirrorTerminalView: TerminalView {
    var appliesHostOutput = false

    nonisolated override func send(source: Terminal, data: ArraySlice<UInt8>) {
        guard Thread.isMainThread, MainActor.assumeIsolated({ appliesHostOutput }) else { return super.send(source: source, data: data) }
    }
}
