import SwiftUI
import AppKit

/// Injects itself as a background view and fires `callback` whenever the
/// hosting NSWindow changes (including the first time the view appears).
struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow?) -> Void

    func makeNSView(context: Context) -> WindowObservingView {
        WindowObservingView(callback: callback)
    }

    func updateNSView(_ nsView: WindowObservingView, context: Context) {
        nsView.callback = callback
    }
}

final class WindowObservingView: NSView {
    var callback: (NSWindow?) -> Void

    init(callback: @escaping (NSWindow?) -> Void) {
        self.callback = callback
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        callback(window)
    }
}
