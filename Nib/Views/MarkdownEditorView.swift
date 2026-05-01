import SwiftUI
import AppKit

// MARK: - NSViewRepresentable

struct MarkdownEditorView: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont
    @Environment(EditorState.self) private var editorState

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, font: font)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = MarkdownTextView(frame: .zero)
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                                  height: CGFloat.greatestFiniteMagnitude)
        textView.drawsBackground = false

        // isRichText = false disables user-facing rich text paste/format controls.
        // Programmatic attribute setting via NSTextStorageDelegate still renders correctly.
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticLinkDetectionEnabled = true
        textView.isContinuousSpellCheckingEnabled = false
        textView.textContainerInset = NSSize(width: 16, height: 12)

        let baseStyle = Self.baseParagraphStyle()
        textView.defaultParagraphStyle = baseStyle
        textView.typingAttributes = [
            .font: context.coordinator.font,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: baseStyle
        ]

        textView.delegate = context.coordinator
        textView.textStorage?.delegate = context.coordinator

        scrollView.documentView = textView

        // Set initial content — NSTextStorageDelegate fires and applies markdown styles
        if !context.coordinator.text.wrappedValue.isEmpty {
            textView.string = context.coordinator.text.wrappedValue
        }

        context.coordinator.setupEditorActions(for: textView, in: editorState)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? MarkdownTextView else { return }
        context.coordinator.font = font

        guard textView.string != text else { return }

        let sel = textView.selectedRange()
        textView.string = text
        let clampedLoc = min(sel.location, (textView.string as NSString).length)
        textView.setSelectedRange(NSRange(location: clampedLoc, length: 0))
        // Styling applied by NSTextStorageDelegate after string is set
    }

    static func baseParagraphStyle() -> NSParagraphStyle {
        let s = NSMutableParagraphStyle()
        s.lineHeightMultiple = 1.4
        return s
    }
}

// MARK: - Custom NSTextView (checkbox interaction)

private final class MarkdownTextView: NSTextView {
    override func mouseDown(with event: NSEvent) {
        if toggleCheckbox(for: event) { return }
        super.mouseDown(with: event)
    }

    private func toggleCheckbox(for event: NSEvent) -> Bool {
        guard let layoutManager, let textContainer else { return false }

        let viewPoint = convert(event.locationInWindow, from: nil)
        let insetPoint = NSPoint(x: viewPoint.x - textContainerInset.width,
                                 y: viewPoint.y - textContainerInset.height)

        var fraction: CGFloat = 0
        let glyphIndex = layoutManager.glyphIndex(for: insetPoint, in: textContainer,
                                                   fractionOfDistanceThroughGlyph: &fraction)
        guard glyphIndex < layoutManager.numberOfGlyphs else { return false }
        let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)

        let nsString = string as NSString
        let lineRange = nsString.lineRange(for: NSRange(location: charIndex, length: 0))
        let lineText = nsString.substring(with: lineRange)
        let lineLen = (lineText as NSString).length

        let cases: [(String, String)] = [
            (#"^(\s*-\s)(\[ \])(\s)"#, "[x]"),
            (#"^(\s*-\s)(\[x\])(\s)"#, "[ ]")
        ]

        for (pattern, replacement) in cases {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = regex.firstMatch(in: lineText, range: NSRange(0..<lineLen)) else { continue }

            let prefixEnd = lineRange.location + match.range.location + match.range.length
            guard charIndex < prefixEnd else { continue }

            let cbRange = NSRange(location: lineRange.location + match.range(at: 2).location,
                                  length: match.range(at: 2).length)
            if shouldChangeText(in: cbRange, replacementString: replacement) {
                textStorage?.replaceCharacters(in: cbRange, with: replacement)
                didChangeText()
                return true
            }
        }
        return false
    }
}

// MARK: - Coordinator

extension MarkdownEditorView {
    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate, @preconcurrency NSTextStorageDelegate {
        var text: Binding<String>
        var font: NSFont
        private var isApplyingStyles = false

        init(text: Binding<String>, font: NSFont) {
            self.text = text
            self.font = font
        }

        // MARK: Editor action wiring

        fileprivate func setupEditorActions(for textView: MarkdownTextView, in editorState: EditorState) {
            editorState.insertAtCursor = { [weak textView] string in
                guard let textView else { return }
                let range = textView.selectedRange()
                if textView.shouldChangeText(in: range, replacementString: string) {
                    textView.textStorage?.replaceCharacters(in: range, with: string)
                    let newLoc = range.location + (string as NSString).length
                    textView.setSelectedRange(NSRange(location: newLoc, length: 0))
                    textView.didChangeText()
                }
            }

            editorState.wrapSelection = { [weak textView] prefix, suffix in
                guard let textView else { return }
                let range = textView.selectedRange()
                let selected = (textView.string as NSString).substring(with: range)
                let replacement = prefix + selected + suffix
                if textView.shouldChangeText(in: range, replacementString: replacement) {
                    textView.textStorage?.replaceCharacters(in: range, with: replacement)
                    let contentLoc = range.location + (prefix as NSString).length
                    let contentLen = selected.isEmpty ? 0 : (selected as NSString).length
                    textView.setSelectedRange(NSRange(location: contentLoc, length: contentLen))
                    textView.didChangeText()
                }
            }
        }

        // MARK: NSTextViewDelegate

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }

        // MARK: NSTextStorageDelegate

        func textStorage(
            _ textStorage: NSTextStorage,
            didProcessEditing editedMask: NSTextStorageEditActions,
            range editedRange: NSRange,
            changeInLength delta: Int
        ) {
            guard editedMask.contains(.editedCharacters), !isApplyingStyles else { return }
            applyMarkdownStyles(to: textStorage)
        }

        // MARK: Styling

        func applyMarkdownStyles(to textStorage: NSTextStorage) {
            guard textStorage.length > 0 else { return }
            isApplyingStyles = true
            defer { isApplyingStyles = false }

            let fullRange = NSRange(location: 0, length: textStorage.length)
            let nsString = textStorage.string as NSString
            let baseStyle = MarkdownEditorView.baseParagraphStyle()

            textStorage.setAttributes([
                .font: font,
                .foregroundColor: NSColor.labelColor,
                .paragraphStyle: baseStyle
            ], range: fullRange)

            applyHeadings(to: textStorage, nsString: nsString)
            applyBold(to: textStorage, nsString: nsString)
            applyItalic(to: textStorage, nsString: nsString)
            applyStrikethrough(to: textStorage, nsString: nsString)
            applyInlineCode(to: textStorage, nsString: nsString)
            applyLinks(to: textStorage, nsString: nsString)
            applyCheckboxes(to: textStorage, nsString: nsString)
        }

        private func eachMatch(
            _ pattern: String,
            options: NSRegularExpression.Options = [],
            in nsString: NSString,
            body: (NSTextCheckingResult) -> Void
        ) {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }
            regex.enumerateMatches(in: nsString as String, range: NSRange(0..<nsString.length)) { match, _, _ in
                guard let match else { return }
                body(match)
            }
        }

        private func applyHeadings(to ts: NSTextStorage, nsString: NSString) {
            eachMatch(#"^(#{1,3})(\s.+)$"#, options: .anchorsMatchLines, in: nsString) { match in
                let hashRange = match.range(at: 1)
                guard hashRange.location != NSNotFound else { return }

                let level = hashRange.length
                let scale: CGFloat = level == 1 ? 1.6 : level == 2 ? 1.35 : 1.15
                let headingFont = NSFont.boldSystemFont(ofSize: font.pointSize * scale)
                let style = NSMutableParagraphStyle()
                style.lineHeightMultiple = 1.4
                style.paragraphSpacingBefore = CGFloat(4 - level) * 4

                ts.addAttributes([.font: headingFont, .paragraphStyle: style], range: match.range)
                ts.addAttribute(.foregroundColor, value: NSColor.tertiaryLabelColor, range: hashRange)
            }
        }

        private func applyBold(to ts: NSTextStorage, nsString: NSString) {
            eachMatch(#"(\*\*|__)(.+?)(\*\*|__)"#, options: .dotMatchesLineSeparators, in: nsString) { match in
                let contentRange = match.range(at: 2)
                guard contentRange.location != NSNotFound, contentRange.location < ts.length else { return }

                let existing = ts.attribute(.font, at: contentRange.location, effectiveRange: nil) as? NSFont ?? font
                ts.addAttribute(.font, value: NSFontManager.shared.convert(existing, toHaveTrait: .boldFontMask), range: contentRange)
                for g in [1, 3] {
                    let r = match.range(at: g)
                    if r.location != NSNotFound {
                        ts.addAttribute(.foregroundColor, value: NSColor.tertiaryLabelColor, range: r)
                    }
                }
            }
        }

        private func applyItalic(to ts: NSTextStorage, nsString: NSString) {
            for pattern in [#"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)"#, #"(?<!_)_(?!_)(.+?)(?<!_)_(?!_)"#] {
                eachMatch(pattern, in: nsString) { match in
                    let contentRange = match.range(at: 1)
                    guard contentRange.location != NSNotFound, contentRange.location < ts.length else { return }

                    let existing = ts.attribute(.font, at: contentRange.location, effectiveRange: nil) as? NSFont ?? font
                    ts.addAttribute(.font, value: NSFontManager.shared.convert(existing, toHaveTrait: .italicFontMask), range: contentRange)
                    let full = match.range
                    for r in [NSRange(location: full.location, length: 1),
                               NSRange(location: NSMaxRange(full) - 1, length: 1)] {
                        ts.addAttribute(.foregroundColor, value: NSColor.tertiaryLabelColor, range: r)
                    }
                }
            }
        }

        private func applyStrikethrough(to ts: NSTextStorage, nsString: NSString) {
            eachMatch(#"(~~)(.+?)(~~)"#, in: nsString) { match in
                let contentRange = match.range(at: 2)
                guard contentRange.location != NSNotFound, NSMaxRange(contentRange) <= ts.length else { return }

                // NSNumber wrapping required — passing Int directly can fail silent in AppKit attribute dictionaries
                ts.addAttributes([
                    .strikethroughStyle: NSNumber(value: NSUnderlineStyle.single.rawValue),
                    .strikethroughColor: NSColor.secondaryLabelColor,
                    .foregroundColor: NSColor.secondaryLabelColor
                ], range: contentRange)

                for r in [match.range(at: 1), match.range(at: 3)] where r.location != NSNotFound {
                    ts.addAttribute(.foregroundColor, value: NSColor.tertiaryLabelColor, range: r)
                }
            }
        }

        private func applyInlineCode(to ts: NSTextStorage, nsString: NSString) {
            eachMatch(#"`([^`\n]+)`"#, in: nsString) { match in
                let fullRange = match.range
                guard fullRange.location != NSNotFound, NSMaxRange(fullRange) <= ts.length else { return }

                let codeFont = NSFont.monospacedSystemFont(ofSize: font.pointSize * 0.92, weight: .regular)
                ts.addAttributes([
                    .font: codeFont,
                    .backgroundColor: NSColor.labelColor.withAlphaComponent(0.07),
                    .foregroundColor: NSColor.labelColor
                ], range: fullRange)
                for r in [NSRange(location: fullRange.location, length: 1),
                           NSRange(location: NSMaxRange(fullRange) - 1, length: 1)] {
                    ts.addAttribute(.foregroundColor, value: NSColor.tertiaryLabelColor, range: r)
                }
            }
        }

        private func applyLinks(to ts: NSTextStorage, nsString: NSString) {
            eachMatch(#"\[([^\]\n]+)\]\(([^)\n]+)\)"#, in: nsString) { match in
                let textRange = match.range(at: 1)
                let urlRange = match.range(at: 2)
                let fullRange = match.range
                guard textRange.location != NSNotFound, urlRange.location != NSNotFound else { return }

                let urlStr = nsString.substring(with: urlRange)
                guard let url = URL(string: urlStr) else { return }

                ts.addAttributes([
                    .foregroundColor: NSColor.linkColor,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .link: url
                ], range: textRange)

                let dim = NSColor.tertiaryLabelColor
                for r in [
                    NSRange(location: fullRange.location, length: 1),
                    NSRange(location: NSMaxRange(textRange), length: 1),
                    NSRange(location: NSMaxRange(textRange) + 1, length: 1),
                    urlRange,
                    NSRange(location: NSMaxRange(fullRange) - 1, length: 1)
                ] where NSMaxRange(r) <= ts.length {
                    ts.addAttribute(.foregroundColor, value: dim, range: r)
                }
            }
        }

        private func applyCheckboxes(to ts: NSTextStorage, nsString: NSString) {
            eachMatch(#"^(\s*-\s)(\[ \]|\[x\])( )"#,
                      options: [.anchorsMatchLines, .caseInsensitive],
                      in: nsString) { match in
                let cbRange = match.range(at: 2)
                guard cbRange.location != NSNotFound else { return }

                let isChecked = nsString.substring(with: cbRange).lowercased().contains("x")

                if isChecked {
                    ts.addAttribute(.foregroundColor, value: NSColor.systemGreen, range: cbRange)

                    let lineRange = nsString.lineRange(for: match.range)
                    let afterCB = NSMaxRange(match.range)
                    let remainLen = max(0, NSMaxRange(lineRange) - afterCB)
                    if remainLen > 0 {
                        let remainRange = NSRange(location: afterCB, length: remainLen)
                        if NSMaxRange(remainRange) <= ts.length {
                            ts.addAttributes([
                                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                                .foregroundColor: NSColor.tertiaryLabelColor
                            ], range: remainRange)
                        }
                    }
                } else {
                    ts.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: cbRange)
                }
            }
        }
    }
}
