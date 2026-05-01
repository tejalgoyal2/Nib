import SwiftUI
import AppKit

struct ScratchpadView: View {
    @Environment(StorageService.self) private var storage
    @State private var editorState = EditorState()

    var body: some View {
        @Bindable var storage = storage

        VStack(spacing: 0) {
            if editorState.showFormatBar {
                QuickFormatBar()
                    .transition(.move(edge: .top).combined(with: .opacity))
                Divider()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            MarkdownEditorView(text: $storage.text, font: .systemFont(ofSize: 14))

            Divider()

            ToolbarView()
        }
        .environment(editorState)
        .frame(
            width: editorState.isExpanded ? 500 : 380,
            height: editorState.isExpanded ? 600 : 420
        )
        .background(.ultraThinMaterial)
        .animation(.spring(duration: 0.3), value: editorState.isExpanded)
        .animation(.spring(duration: 0.25), value: editorState.showFormatBar)
        .background(
            WindowAccessor { window in
                editorState.attachWindow(window)
            }
        )
        .onAppear {
            editorState.setupKeyMonitor()
        }
        .onDisappear {
            editorState.teardownKeyMonitor()
        }
    }
}
