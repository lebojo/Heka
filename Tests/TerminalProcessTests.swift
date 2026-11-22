import AppKit
import SwiftTerm
import SwiftUI

extension SwiftUI.Color {
    static let surface = SwiftUI.Color(nsColor: .textBackgroundColor)
    static let textPrimary = SwiftUI.Color.primary
}

@MainActor private final class Receiver: TerminalProcessReceiver {
    var output = Data()
    var localUses = 0
    var exitCodes: [Int32?] = []

    func terminalReceived(_ slice: ArraySlice<UInt8>) { output.append(contentsOf: slice) }
    func terminalUsedLocally() { localUses += 1 }
    func terminalResized() {}
    func terminalTitleChanged(_ title: String) {}
    func terminalProcessEnded(exitCode: Int32?) { exitCodes.append(exitCode) }
}

@main @MainActor struct TerminalProcessTests {
    static func require(_ condition: Bool, _ message: String) {
        precondition(condition, message)
    }

    fileprivate static func run(_ script: String) async -> (view: ActivityTerminalView, receiver: Receiver) {
        let view = ActivityTerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 500))
        let receiver = Receiver()
        view.receiver = receiver
        view.remoteGrid = TerminalGridSize(columns: 80, rows: 24)
        view.process.startProcess(executable: "/bin/bash", args: ["--noprofile", "--norc", "-c", script],
                                  environment: ["PATH=/usr/bin:/bin", "TERM=xterm-256color", "LANG=en_US.UTF-8"],
                                  currentDirectory: NSTemporaryDirectory())
        require(view.process.running, "The shell starts")
        let deadline = ContinuousClock.now + .seconds(15)
        while receiver.exitCodes.isEmpty, ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(20))
        }
        require(!receiver.exitCodes.isEmpty, "The shell reports its exit")
        return (view, receiver)
    }

    static func main() async {
        let start = Date.now
        let answered = await run(#"stty -echo; printf 'first\n'; printf '\033[c'; IFS= read -r -s -d c reply; printf 'reply:%q\n' "$reply"; exit 1"#)
        let text = String(decoding: answered.receiver.output, as: UTF8.self)
        require(text.contains("first") && text.contains("reply:"), "Process output reaches the mirror and idle detection: \(text.debugDescription)")
        require(answered.view.lastOutput > start, "Output updates the last output date used by heka terminal wait")
        require(answered.view.recentLines(5).contains("reply:$'\\E[?"), "The terminal answers the device query: \(answered.view.recentLines(5))")
        require(answered.receiver.localUses == 0, "An answer to the host is not local use")
        require(answered.receiver.exitCodes == [1], "Exit code 1 is reported as 1: \(answered.receiver.exitCodes)")
        print("PASS process output, host answers and exit code")

        let signaled = await run("kill -KILL $$")
        require(signaled.receiver.exitCodes == [nil], "A shell killed by a signal has no exit code: \(signaled.receiver.exitCodes)")
        let exited = await run("exit 3")
        require(exited.receiver.exitCodes == [3], "Exit code 3 is reported as 3: \(exited.receiver.exitCodes)")
        exited.view.send(source: exited.view, data: Array("x".utf8)[...])
        require(exited.receiver.localUses == 1, "Typing in the Mac terminal is local use")
        print("PASS signal and exit statuses, local use")
    }
}
