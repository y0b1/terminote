# Terminote contributor guide

## Product purpose

Terminote is a single persistent macOS menu-bar scratchpad for compiling thoughts, rough plans, and prompts while vibecoding. Preserve the feeling of opening one instant sheet of plain text, writing, and dismissing it. Do not turn Terminote into a multi-note workspace, knowledge base, Markdown editor, task manager, or cloud service unless the user explicitly changes the product direction.

## Product invariants

- Keep the note plain UTF-8 text so it can be copied directly into coding agents and editors.
- Keep one note, local-first storage, automatic saving, and revision history. There is intentionally no manual note Save command.
- Opening, typing, copying, and closing must remain keyboard-first and immediate.
- Escape closes the panel. The global shortcut toggles it. Ordinary menu-bar left-click opens it; right-click and Control-click open the context menu.
- A line beginning with `- ` autoformats to the portable plain-text marker `• `. Return continues a non-empty bullet. Backspace immediately after an empty marker removes it and returns to normal text. Empty bullets also exit on Return.
- Both Command-Z and Control-Z undo; adding Shift performs redo. Smart bullet edits must each undo as one action.
- Avoid rich-text-only structures. Editor features must serialize predictably to `note.txt`.

## Themes

- Theme settings control the panel background, outline color, background opacity, and optional Liquid Glass.
- Color controls should use the native macOS color picker, including its color-wheel interface.
- Theme edits are drafts until the user presses Save. Cancel must leave both the active theme and theme history unchanged.
- Add an entry to saved-theme history only when a changed theme is explicitly saved. Deduplicate identical themes and keep the history bounded.
- Liquid Glass is available only on macOS 26 or newer. Guard its APIs with availability checks and retain a functional colored-background fallback because the package minimum remains macOS 14.
- Maintain readable text contrast for user-selected background colors and preserve clear focus, selection, and caret states.

## Architecture and persistence

- The app is a Swift Package using SwiftUI for app/popover composition and AppKit for the text editor, window integration, menu handling, and global hotkey support.
- The note lives at `~/Library/Application Support/Terminote/note.txt`.
- The newest 20 note revisions live in the adjacent `history` directory.
- Selection, panel size, shortcut, line-number visibility, and appearance settings use `UserDefaults`.
- Migrations from the legacy Scratch app and existing preference keys must remain backward-compatible.
- Do not silently discard or replace user data. Keep note writes atomic and flush pending edits when the panel closes, the Mac sleeps, or the app quits.

## Interaction and visual quality

- Use native macOS behavior where practical. Dense desktop controls should have at least a 40×40-point hit target.
- Keep animation restrained because opening and dismissing the panel are high-frequency actions.
- Preserve the current compact, monospaced editor character while allowing user-selected colors and transparency.
- Validate keyboard focus, undo/redo, selection persistence, line numbers, light and dark custom colors, reduced opacity, and Liquid Glass fallback behavior.

## Build and verification

- Build with `swift build`.
- Bundle with `make bundle` and create the installer with `make dmg`.
- Add focused tests for pure editing and settings behavior. Run `swift test` whenever a test target is present.
- Before handing off UI changes, check the built app on the oldest supported macOS behavior path and, when available, the macOS 26 Liquid Glass path.

## Release artifact requirement

- Every user-facing release must include an already-built DMG at `dist/Terminote-<version>.dmg` so users can download and install Terminote without Xcode or a local build.
- Keep the DMG version synchronized with `CFBundleShortVersionString` in `Resources/Info.plist`.
- Rebuild the DMG after any source change that affects users, verify it mounts and contains both `Terminote.app` and the Applications shortcut, and include the DMG in the repository or attached release assets.
- Keep generated app bundles and cask scratch output ignored; the versioned DMG is the intended downloadable binary artifact.
