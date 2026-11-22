import AppKit
import SwiftTerm

final class ActivityTerminalView: SharedProcessTerminalView {
    private(set) var lastOutput = Date.distantPast
    var remoteGrid: TerminalGridSize? {
        didSet {
            guard remoteGrid != oldValue else { return }
            setFrameSize(oldValue == nil ? frame.size : hostedSize)
        }
    }
    private var hostedSize = NSSize.zero
    private var forwardsRemoteInput = false

    var visibleLines: [String] {
        visibleRowsText(0..<terminalDimensions.rows)
    }

    override func dataReceived(slice: ArraySlice<UInt8>) {
        lastOutput = .now
        super.dataReceived(slice: slice)
    }

    override func setFrameSize(_ newSize: NSSize) {
        hostedSize = newSize
        guard let pinned = remoteGrid.flatMap(frameSize(for:)) else { return super.setFrameSize(newSize) }
        if pinned != frame.size { super.setFrameSize(pinned) }
    }

    override func send(source: TerminalView, data: ArraySlice<UInt8>) {
        super.send(source: source, data: data)
        guard remoteGrid != nil, !forwardsRemoteInput, !data.isTerminalFocusReport, !data.isTerminalMouseMotionReport else { return }
        receiver?.terminalUsedLocally()
    }

    func sendRemoteInput(_ data: ArraySlice<UInt8>) {
        forwardsRemoteInput = true
        defer { forwardsRemoteInput = false }
        send(source: self, data: data)
    }

    func refitRemoteGrid() {
        guard remoteGrid != nil else { return }
        setFrameSize(hostedSize)
    }

    private func frameSize(for grid: TerminalGridSize) -> NSSize? {
        let current = terminalDimensions
        return grid.frameSize(scaling: getOptimalFrameSize().size, columns: current.cols, rows: current.rows,
                              scrollerWidth: NSScroller.scrollerWidth(for: .regular, scrollerStyle: scrollerStyle))
    }
}
