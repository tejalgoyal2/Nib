# Nib

A menu bar scratchpad for macOS. One note. Always there. Gone when you don't need it.

I built this because every time I had a quick thought, a snippet to paste, or a draft to stage... I'd open Notes. Then Notes would ask me which folder. Then I'd create a new note. Then I'd forget about it in a pile of 300 other "Untitled" notes.

Nib is the opposite of that. It's a single text box that lives in your menu bar. Click the icon, type, close it. Your text is still there when you come back. That's it. That's the whole app.

---

## What it does

- **Lives in your menu bar** — no Dock icon, no window management, no alt-tabbing. Click the pen nib icon, start typing.
- **Inline Markdown** — bold, italic, strikethrough, headings, checkboxes, inline code, links. Styled live as you type, the way a text editor should work.
- **Actually remembers your text** — persists locally between app restarts. No iCloud, no servers, no accounts. Just a file on your Mac.
- **Pin it** — float the window above everything, including full-screen apps. Write while you reference something else.
- **Expand it** — need more room? One click to go bigger. One click to go back.
- **Copy all** — copies the entire scratchpad to your clipboard. One button.
- **Quick format bar** — toggle a formatting toolbar for bold, italic, strikethrough, code, headings, bullets. Or just type the Markdown yourself. Both work.
- **Interactive checkboxes** — type `- [ ] thing` and click to toggle it. Checked items get struck through because *that's satisfying.*
- **Word & character count** — always visible in the toolbar. Useful for tweets, commit messages, and arguing about whether something is "too long."
- **Share** — native macOS share sheet. Send your scratchpad to Mail, Messages, whatever.
- **Liquid Glass UI** — built for macOS Tahoe. The toolbar uses Apple's Liquid Glass effects because if you're going to stare at an app, it should look good.

## What it doesn't do

- Multiple notes. That's a different app. This is a scratchpad.
- Cloud sync. Your text stays on your Mac. That's a feature, not a limitation.
- Folders, tags, categories, or any organizational system. You don't organize a Post-it note.
- Track you. No analytics, no telemetry, no network calls. The app doesn't talk to the internet.

---

## Requirements

- **macOS 26 (Tahoe)** or later
- That's it

If you're not on macOS 26... update. It's been out since September 2025. You're running out of excuses.

---

## Installation

1. Download `Nib.app` from [Releases](https://github.com/tejalgoyal2/Nib/releases)
2. Drag it to `/Applications`
3. Open it. Look up at your menu bar. See the pen nib icon? Click it.
4. Start typing.

> **Note:** Nib is signed with a free developer certificate, so macOS might give you the "unidentified developer" warning on first launch. Right-click the app → Open → Open. You only have to do this once. I'm not paying Apple $99/year to avoid a dialog box.

---

## Keyboard shortcuts

| Shortcut | What it does |
|---|---|
| `Esc` | Dismiss the popover |
| `⌘B` | Bold selection |
| `⌘I` | Italic selection |
| `⌘⇧X` | Strikethrough selection |
| `⌘A` | Select all |
| `⌘C` / `⌘V` / `⌘X` | Copy / paste / cut |
| `⌘Z` / `⇧⌘Z` | Undo / redo |

---

## Privacy

Your text never leaves your Mac. Nib stores one file in `~/Library/Application Support/Nib/scratchpad.json`. That's it. No servers, no accounts, no analytics SDKs. I literally cannot read your notes.

---

## Building from source

```bash
git clone https://github.com/tejalgoyal2/Nib.git
cd Nib
open Nib.xcodeproj
```

Hit `⌘R` in Xcode 26. SPM dependencies (KeyboardShortcuts, MarkdownUI, LaunchAtLogin-Modern) resolve automatically.

Minimum deployment target is macOS 26.0.

---

## Coming soon

- Global keyboard shortcut to summon/dismiss (settings UI is in progress)
- One-way export to Notion — write here, send there
- Launch at login toggle
- Font customization
- Tip jar (the app is free. If it saves you time, you can buy me a coffee. Or don't. It'll keep working either way.)

---

## Tech stack

Swift + SwiftUI, `MenuBarExtra`, `NSTextView` for the editor, Liquid Glass for the toolbar, and exactly three SPM packages. No Electron. No web views. No 150MB runtime for a text box.

---

## License

MIT. Do whatever you want with it.

---

*Built by [Tejal Goyal](https://linkedin.com/in/tejalgoyal). Powered by too much coffee and a refusal to use Apple Notes.*
