#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/Resources/Info.plist")"
DIST_DIR="$ROOT_DIR/dist"
DMG_PATH="$DIST_DIR/Terminote-$VERSION.dmg"
STAGING_DIR="$(mktemp -d)"

trap 'rm -rf "$STAGING_DIR"' EXIT

"$ROOT_DIR/scripts/bundle.sh"
mkdir -p "$DIST_DIR"
ditto "$ROOT_DIR/Terminote.app" "$STAGING_DIR/Terminote.app"
ln -s /Applications "$STAGING_DIR/Applications"
hdiutil create \
    -volname "Terminote" \
    -srcfolder "$STAGING_DIR" \
    -format UDZO \
    -ov \
    "$DMG_PATH"

echo "Built $DMG_PATH"
