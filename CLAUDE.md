# Nib — Menu Bar Scratchpad for macOS

## What this is
A menu bar-only scratchpad app for macOS 26 (Tahoe). Single persistent note with inline Markdown, Liquid Glass UI, one-way Notion export, and an optional tip jar. No Dock icon. No iCloud sync. No servers.

## Tech stack
- Swift + SwiftUI, macOS 26.0 minimum deployment target
- Xcode 26.4, Swift 6.2
- MenuBarExtra for menu bar presence
- NSTextView (wrapped in NSViewRepresentable) for the text editor — NOT SwiftUI TextEditor
- Liquid Glass (.glassEffect()) on controls and toolbar
- Local file storage in ~/Library/Application Support/Nib/
- Notion API token in macOS Keychain via Security.framework
- SPM packages (already added in Xcode):
  - KeyboardShortcuts (https://github.com/sindresorhus/KeyboardShortcuts)
  - MarkdownUI (https://github.com/gonzalezreal/swift-markdown-ui)
  - LaunchAtLogin-Modern (https://github.com/sindresorhus/LaunchAtLogin-Modern)

## Architecture
- App lifecycle via SwiftUI App protocol with MenuBarExtra scene
- LSUIElement = YES in Info.plist (no Dock icon)
- NSPanel subclass for float-on-top behavior
- Bottom toolbar with: pin, settings, format toggle, checkbox insert, expand, copy all, share/notion
- Word and character count in toolbar left side
- Settings window (SwiftUI Settings scene) for: global hotkey, font, font size, Notion token, tip jar
- File structure:
  - /Views — all SwiftUI views
  - /Models — data models
  - /Services — StorageService, KeychainService, HotkeyService, NotionExporter, MarkdownParser
  - /Utilities — Constants, Extensions

## CRITICAL RULES — follow these at all times

### Platform
- This is a macOS app. NEVER use UIKit. Use AppKit (NSTextView, NSWindow, NSPanel, NSWorkspace, etc.)
- Target macOS 26.0 minimum. Use the latest macOS 26 / Xcode 26 APIs freely. Do NOT use deprecated APIs.
- If an API was deprecated in macOS 26, use the modern replacement.

### Swift 6.2 concurrency
- Xcode 26 uses Swift 6.2 with strict concurrency checking enabled by default.
- All @Observable classes that touch UI must be @MainActor.
- Use async/await for all asynchronous work. No completion handlers.
- Be explicit about actor isolation. Mark closures @Sendable when needed.
- If you get concurrency warnings/errors, fix them properly — do NOT suppress with @unchecked Sendable.

### Liquid Glass rules
- .glassEffect() goes ONLY on floating controls (toolbar buttons, format bar, action buttons)
- NEVER put .glassEffect() on content areas (text editor, lists, backgrounds)
- NEVER stack glass on glass — glass cannot sample other glass
- Group related glass elements inside GlassEffectContainer for consistent rendering
- Use .glassEffect(.regular.interactive()) for buttons the user taps
- Use .glassEffect(.regular.tint(.blue)) sparingly for active/selected state only
- Use .containerConcentric corner radius for alignment with system windows
- Let Liquid Glass handle dark/light mode automatically — do NOT hardcode colors

### Security
- App Sandbox is enabled. Entitlements: com.apple.security.network.client (Notion API), com.apple.security.files.user-selected.read-write (file export)
- Hardened Runtime is enabled
- Notion API token: store ONLY in macOS Keychain (Security.framework). NEVER in UserDefaults, NEVER in files, NEVER in logs, NEVER print to console
- Scratchpad content: store in ~/Library/Application Support/Nib/scratchpad.json. NEVER transmit unless user explicitly clicks "Send to Notion"
- Zero analytics SDKs. Zero telemetry. Zero tracking. No network calls except user-initiated Notion export.

### Code style
- SwiftUI views: small, composable, single-responsibility. One view per file.
- MVVM pattern: Views observe @Observable classes. No business logic in views.
- Error handling: NEVER crash. Always catch errors and show user-friendly alerts or fallbacks.
- Comments: brief, explain WHY not WHAT. No obvious comments like "// creates a button".
- Naming: Swift conventions. camelCase for variables/functions, PascalCase for types.
- No force unwraps (!) unless there is a guaranteed invariant with a comment explaining why.

### UX principles
- The app must feel instant. No loading screens, no spinners except for Notion network calls.
- Click-outside-popover should dismiss it (unless pinned).
- Escape key dismisses the popover (unless pinned).
- All text operations (copy, clear, format) should give brief visual feedback.
- The app should work fully offline. Notion is a bonus feature, not a dependency.
- Placeholder text ("Start typing...") should disappear on first keystroke, not on focus.
