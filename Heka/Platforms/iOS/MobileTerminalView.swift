import SwiftUI
import SwiftTerm
import Observation

@MainActor @Observable final class MobileTerminalSession: NSObject, TerminalViewDelegate {
    let identity: UUID
    let isChat: Bool
    private(set) var messages: [SessionMessage] = []
    private(set) var chatSource: SessionChatSource = .terminal
    private(set) var agentOptions = AgentOptions()
    private(set) var hasExited = false
    private(set) var exitCode: Int32?
    private(set) var canvasSize = CGSize.zero
    @ObservationIgnored let view: MobileMirrorTerminalView?
    @ObservationIgnored private var viewport = CGSize.zero
    @ObservationIgnored private var requestedGrid: TerminalGridSize?
    @ObservationIgnored private var gridRequest: Task<Void, Never>?
    @ObservationIgnored private let sendInput: (Data) -> Void
    @ObservationIgnored private let requestGrid: (TerminalGridSize) -> Void

    init(identity: UUID, isChat: Bool, sendInput: @escaping (Data) -> Void, requestGrid: @escaping (TerminalGridSize) -> Void) {
        self.identity = identity
        self.isChat = isChat
        self.sendInput = sendInput
        self.requestGrid = requestGrid
        view = isChat ? nil : MobileMirrorTerminalView(frame: .zero)
        super.init()
        view?.font = .monospacedSystemFont(ofSize: TerminalAppearance.defaultFontSize, weight: .regular)
        view?.terminalDelegate = self
    }

    private var fittingGrid: TerminalGridSize? {
        guard let view, viewport.width > 0, viewport.height > 0 else { return nil }
        let grid = view.terminalDimensions
        let size = view.getOptimalFrameSize().size
        guard size.width > 0, size.height > 0 else { return nil }
        return TerminalGridSize(columns: Int(viewport.width * CGFloat(grid.cols) / size.width),
                                rows: Int(viewport.height * CGFloat(grid.rows) / size.height))
    }

    @discardableResult func apply(_ snapshot: RemoteTerminalSnapshot) -> Bool {
        if hasExited != snapshot.hasExited { hasExited = snapshot.hasExited }
        if exitCode != snapshot.exitCode { exitCode = snapshot.exitCode }
        if chatSource != snapshot.chatSource { chatSource = snapshot.chatSource }
        let options = snapshot.agentOptions ?? AgentOptions()
        if agentOptions != options { agentOptions = options }
        guard (0...messages.count).contains(snapshot.transcriptDropped),
              (0...(messages.count - snapshot.transcriptDropped)).contains(snapshot.transcriptStart) else { return false }
        let changesTranscript = snapshot.transcriptDropped > 0 || snapshot.transcriptStart < messages.count - snapshot.transcriptDropped
            || !snapshot.transcript.isEmpty || snapshot.transcriptAppend != nil
        if changesTranscript {
            var updated = messages
            updated.removeFirst(snapshot.transcriptDropped)
            updated.replaceSubrange(snapshot.transcriptStart..., with: snapshot.transcript)
            if let append = snapshot.transcriptAppend {
                guard let last = updated.last, last.id == append.id, let text = append.applied(to: last.text) else { return false }
                updated[updated.count - 1].text = text
            }
            messages = updated
        }
        guard let view else { return true }
        view.appliesHostOutput = true
        defer { view.appliesHostOutput = false }
        let grid = view.terminalDimensions
        if grid.cols != snapshot.mirroredColumns || grid.rows != snapshot.mirroredRows {
            view.resize(cols: snapshot.mirroredColumns, rows: snapshot.mirroredRows)
        }
        updateCanvasSize()
        if !snapshot.output.isEmpty { view.feed(byteArray: Array(snapshot.output)[...]) }
        return true
    }

    func fit(_ viewport: CGSize) {
        guard self.viewport != viewport else { return }
        self.viewport = viewport
        scheduleGridRequest()
    }

    func setFontSize(_ size: Double) {
        guard let view, view.font.pointSize != CGFloat(size) else { return }
        let origin = view.frame.origin
        view.frame = .zero
        view.font = .monospacedSystemFont(ofSize: size, weight: .regular)
        updateCanvasSize()
        view.frame = CGRect(origin: origin, size: canvasSize)
        scheduleGridRequest()
    }

    func resendGrid() {
        guard let requestedGrid else { return }
        requestGrid(requestedGrid)
    }

    private func updateCanvasSize() {
        guard let view else { return }
        let size = view.getOptimalFrameSize().size
        let canvas = CGSize(width: ceil(size.width), height: ceil(size.height))
        if canvasSize != canvas { canvasSize = canvas }
    }

    private func scheduleGridRequest() {
        gridRequest?.cancel()
        gridRequest = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(150)) } catch { return }
            self?.requestFittingGrid()
        }
    }

    private func requestFittingGrid() {
        guard let grid = fittingGrid, grid != requestedGrid else { return }
        requestedGrid = grid
        requestGrid(grid)
    }

    func send(source: TerminalView, data: ArraySlice<UInt8>) {
        sendInput(Data(data))
    }
    func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {}
    func setTerminalTitle(source: TerminalView, title: String) {}
    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}
    func scrolled(source: TerminalView, position: Double) {}
    func requestOpenLink(source: TerminalView, request: TerminalLinkRequest) {
        guard let url = URL(string: request.link), ["https", "http"].contains(url.scheme) else { return }
        UIApplication.shared.open(url)
    }
    func bell(source: TerminalView) {}
    func clipboardCopy(source: TerminalView, content: Data) {}
    func rangeChanged(source: TerminalView, startY: Int, endY: Int) {}
}
