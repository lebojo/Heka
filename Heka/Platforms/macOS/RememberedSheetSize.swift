import AppKit
import SwiftUI

extension EnvironmentValues {
    @Entry var sheetSpace: CGSize?
}

struct RememberedSheetSize: ViewModifier {
    @MainActor private final class RestoredSize {
        private var size: CGSize?

        func size(of kind: PreviewSheetKind, fitting space: CGSize?) -> CGSize {
            if let size { return size }
            let defaults = UserDefaults.standard
            let restored = kind.restoredSize(width: defaults.double(forKey: kind.widthKey), height: defaults.double(forKey: kind.heightKey),
                                             fitting: space)
            size = restored
            return restored
        }
    }

    @Environment(\.sheetSpace) private var space

    @State private var restored = RestoredSize()

    let kind: PreviewSheetKind

    func body(content: Content) -> some View {
        let idealSize = restored.size(of: kind, fitting: space)
        return content
            .frame(minWidth: PreviewSheetKind.minimumSize.width, idealWidth: idealSize.width, maxWidth: .infinity,
                   minHeight: PreviewSheetKind.minimumSize.height, idealHeight: idealSize.height, maxHeight: .infinity)
            .background { SheetResizeObserver(kind: kind) }
    }
}

struct SheetSpaceProvider: ViewModifier {
    @State private var space: CGSize?

    func body(content: Content) -> some View {
        content
            .environment(\.sheetSpace, space)
            .background { SheetSpaceReader(space: $space) }
    }
}

private struct SheetSpaceReader: NSViewRepresentable {
    final class ReaderView: NSView {
        var onChange: (CGSize?) -> Void = { _ in }
        private var observations: [NSObjectProtocol] = []

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            observations.forEach(NotificationCenter.default.removeObserver)
            observations = []
            guard let window else { return onChange(nil) }
            let notifications: [(Notification.Name, AnyObject?)] = [(NSWindow.didChangeScreenNotification, window),
                                                                   (NSWindow.didEndLiveResizeNotification, window),
                                                                   (NSApplication.didChangeScreenParametersNotification, nil)]
            observations = notifications.map { name, object in
                NotificationCenter.default.addObserver(forName: name, object: object, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.report() }
                }
            }
            report()
        }

        func report() {
            guard let window, let screen = window.screen ?? NSScreen.main else { return onChange(nil) }
            let titleBarHeight = window.frame.height - window.contentLayoutRect.height
            onChange(CGSize(width: screen.visibleFrame.width, height: screen.visibleFrame.height - titleBarHeight))
        }
    }

    @Binding var space: CGSize?

    func makeNSView(context: Context) -> ReaderView {
        ReaderView()
    }

    func updateNSView(_ nsView: ReaderView, context: Context) {
        nsView.onChange = { size in
            DispatchQueue.main.async { if space != size { space = size } }
        }
        nsView.report()
    }
}
