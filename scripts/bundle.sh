#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
APP_DIR="$ROOT_DIR/Terminote.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICONSET_DIR="$(mktemp -d)/AppIcon.iconset"
BIN_DIR="$(cd "$ROOT_DIR" && swift build --show-bin-path)"

trap 'rm -rf "${ICONSET_DIR:h}"' EXIT

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$ICONSET_DIR"
cp "$BIN_DIR/Terminote" "$MACOS_DIR/Terminote"
cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

cp "$ROOT_DIR/Resources/TerminoteIcon.png" "$ICONSET_DIR/icon_512x512@2x.png"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$ICONSET_DIR/icon_512x512@2x.png" --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z "$double" "$double" "$ICONSET_DIR/icon_512x512@2x.png" --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"

codesign --force --deep --sign - "$APP_DIR"
echo "Built $APP_DIR"
