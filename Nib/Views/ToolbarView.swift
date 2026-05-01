import SwiftUI
import AppKit

struct ToolbarView: View {
    @Environment(StorageService.self) private var storage
    @Environment(EditorState.self) private var editorState
    @Environment(\.openSettings) private var openSettings

    @State private var showCopied = false

    private var wordCount: Int {
        storage.text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
    }

    private var charCount: Int {
        storage.text.count
    }

    var body: some View {
        HStack(spacing: 0) {
            Text("\(wordCount) words · \(charCount) chars")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()

            Spacer()

            GlassEffectContainer {
                HStack(spacing: 2) {
                    ToolbarIconButton(systemImage: "gear", tooltip: "Settings") {
                        openSettings()
                    }

                    ToolbarIconButton(
                        systemImage: "textformat",
                        isActive: editorState.showFormatBar,
                        tooltip: "Format bar"
                    ) {
                        editorState.showFormatBar.toggle()
                    }

                    ToolbarIconButton(systemImage: "checklist", tooltip: "Insert checkbox") {
                        editorState.insertAtCursor?("- [ ] ")
                    }

                    ToolbarIconButton(
                        systemImage: editorState.isExpanded
                            ? "arrow.down.right.and.arrow.up.left"
                            : "arrow.up.left.and.arrow.down.right",
                        isActive: editorState.isExpanded,
                        tooltip: editorState.isExpanded ? "Collapse" : "Expand"
                    ) {
                        editorState.isExpanded.toggle()
                    }

                    ToolbarIconButton(
                        systemImage: showCopied ? "checkmark" : "doc.on.doc",
                        isSuccess: showCopied,
                        tooltip: "Copy all"
                    ) {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(storage.text, forType: .string)
                        showCopied = true
                        Task {
                            try? await Task.sleep(for: .seconds(1.5))
                            showCopied = false
                        }
                    }

                    ShareButton(text: storage.text)
                        .frame(width: 30, height: 30)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Toolbar icon button

private struct ToolbarIconButton: View {
    let systemImage: String
    var isActive: Bool = false
    var isSuccess: Bool = false
    var tooltip: String = ""
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
                .foregroundStyle(iconColor)
        }
        .buttonStyle(.plain)
        .background(buttonBackground)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .onHover { isHovering = $0 }
        .animation(.easeInOut(duration: 0.12), value: isHovering)
        .help(tooltip)
    }

    private var iconColor: Color {
        if isSuccess { return .green }
        if isActive { return .accentColor }
        return isHovering ? .primary : .secondary
    }

    @ViewBuilder
    private var buttonBackground: some View {
        if isSuccess {
            Color.green.opacity(0.18).background(.regularMaterial)
        } else if isActive {
            Color.accentColor.opacity(0.18).background(.regularMaterial)
        } else if isHovering {
            Color.primary.opacity(0.07)
        } else {
            Color.clear
        }
    }
}

// MARK: - Share button (NSViewRepresentable for NSSharingServicePicker)

private struct ShareButton: NSViewRepresentable {
    var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: text)
    }

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton()
        button.image = NSImage(systemSymbolName: "square.and.arrow.up",
                               accessibilityDescription: "Share")
        button.isBordered = false
        button.imageScaling = .scaleProportionallyDown
        button.target = context.coordinator
        button.action = #selector(Coordinator.share(_:))
        return button
    }

    func updateNSView(_ nsView: NSButton, context: Context) {
        context.coordinator.text = text
    }

    @MainActor
    final class Coordinator: NSObject {
        var text: String
        init(text: String) { self.text = text }

        @objc func share(_ sender: NSButton) {
            let picker = NSSharingServicePicker(items: [text as NSString])
            picker.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        }
    }
}
