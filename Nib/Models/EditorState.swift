@preconcurrency import AppKit

@MainActor
@Observable
final class EditorState {
    var showFormatBar = false
    var isExpanded = false

    var window: NSWindow?

    var insertAtCursor: ((String) -> Void)?
    var wrapSelection: ((String, String) -> Void)?

    @ObservationIgnored private var keyMonitor: Any?
    @ObservationIgnored private var windowLevelObserver: Any?

    func attachWindow(_ newWindow: NSWindow?) {
        if let obs = windowLevelObserver {
            NotificationCenter.default.removeObserver(obs)
            windowLevelObserver = nil
        }

        window = newWindow
        applyWindowBehavior()

        guard let newWindow else { return }

        // SwiftUI's MenuBarExtra resets level/hidesOnDeactivate after each appearance.
        // Re-apply on the next run-loop tick to win that race.
        windowLevelObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: newWindow,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.applyWindowBehavior()
            }
        }
    }

    func applyWindowBehavior() {
        guard let window else { return }
        // Always float above other apps and stay visible when the user switches apps.
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hidesOnDeactivate = false
    }

    func setupKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event }
            return MainActor.assumeIsolated {
                guard let self else { return event }
                self.window?.close()
                return nil
            }
        }
    }

    func teardownKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }
}
