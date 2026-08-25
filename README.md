<p align="center">
  <img src="Resources/TerminoteIcon.png" width="160" alt="Terminote icon">
</p>

# Terminote

Terminote is a single persistent macOS menu-bar scratchpad. The note autosaves locally with revision history and no save command.

## Requirements

- macOS 14 or newer
- Xcode 15.0 or newer, or matching Swift 5.9+ command-line tools

## Build and run

```sh
swift build
./scripts/bundle.sh
open ./Terminote.app
```

Or use:

```sh
make run
```

The bundle script creates `Terminote.app` in the repository root, generates its icon, and applies an ad-hoc signature.

## Install

```sh
sudo ditto ./Terminote.app /Applications/Terminote.app
open /Applications/Terminote.app
```

Right-click the menu-bar icon to toggle line numbers, open the note folder, change the shortcut, or quit.

Terminote stores its note at `~/Library/Application Support/Terminote/note.txt`. On first launch it copies existing data from `~/Library/Application Support/Scratch` when present. The 20 newest autosaved revisions are kept in the `history` subfolder.

The default global shortcut is Control–Option–Space.

## DMG

Build a compressed disk image containing `Terminote.app` and an Applications shortcut:

```sh
make dmg
```

The result is `dist/Terminote-1.0.0.dmg`.

## Homebrew

Generate a checksummed local cask from the DMG:

```sh
make cask
brew install --cask ./dist/terminote.rb
```

For a public tap, upload the DMG to an immutable release URL, then generate the cask with that base URL and your project homepage:

```sh
TERMINOTE_RELEASE_BASE_URL="https://github.com/y0b1/terminote/releases/download/v1.0.0" \
TERMINOTE_HOMEPAGE="https://github.com/y0b1/terminote" \
./scripts/cask.sh
```

Copy `dist/terminote.rb` into the tap's `Casks/` directory. Homebrew users can then install it with `brew install --cask OWNER/TAP/terminote`.
