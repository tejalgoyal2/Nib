import SwiftUI
import AppKit

struct QuickFormatBar: View {
    @Environment(EditorState.self) private var editorState

    var body: some View {
        HStack(spacing: 0) {
            GlassEffectContainer {
                HStack(spacing: 2) {
                    FormatButton(label: "B", bold: true, tooltip: "Bold") {
                        editorState.wrapSelection?("**", "**")
                    }
                    FormatButton(label: "I", italic: true, tooltip: "Italic") {
                        editorState.wrapSelection?("_", "_")
                    }
                    FormatButton(label: "S", strikethrough: true, tooltip: "Strikethrough") {
                        editorState.wrapSelection?("~~", "~~")
                    }
                    FormatButton(label: "`", monospaced: true, tooltip: "Inline code") {
                        editorState.wrapSelection?("`", "`")
                    }
                    FormatButton(label: "#", tooltip: "Heading") {
                        editorState.insertAtCursor?("# ")
                    }
                    FormatButton(label: "•", tooltip: "Bullet list") {
                        editorState.insertAtCursor?("- ")
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

private struct FormatButton: View {
    let label: String
    var bold: Bool = false
    var italic: Bool = false
    var strikethrough: Bool = false
    var monospaced: Bool = false
    let tooltip: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(buttonFont)
                .frame(width: 36, height: 32)
                .contentShape(Rectangle())
                .foregroundStyle(isHovering ? Color.primary : .secondary)
                .strikethrough(strikethrough)
        }
        .buttonStyle(.plain)
        .background(isHovering ? Color.primary.opacity(0.07) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .onHover { isHovering = $0 }
        .animation(.easeInOut(duration: 0.12), value: isHovering)
        .help(tooltip)
    }

    private var buttonFont: Font {
        var f = Font.system(size: 14, weight: .semibold)
        if italic { f = f.italic() }
        if monospaced { f = f.monospaced() }
        return f
    }
}
