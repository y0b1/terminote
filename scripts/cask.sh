#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/Resources/Info.plist")"
DIST_DIR="$ROOT_DIR/dist"
DMG_NAME="Terminote-$VERSION.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"
CASK_PATH="$DIST_DIR/terminote.rb"
RELEASE_BASE_URL="${TERMINOTE_RELEASE_BASE_URL:-file://$DIST_DIR}"
HOMEPAGE="${TERMINOTE_HOMEPAGE:-https://github.com/y0b1/terminote}"

if [[ ! -f "$DMG_PATH" ]]; then
    "$ROOT_DIR/scripts/dmg.sh"
fi

CHECKSUM="$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')"

cat > "$CASK_PATH" <<EOF
cask "terminote" do
  version "$VERSION"
  sha256 "$CHECKSUM"

  url "$RELEASE_BASE_URL/Terminote-#{version}.dmg"
  name "Terminote"
  desc "Persistent single-note menu bar scratchpad"
  homepage "$HOMEPAGE"

  depends_on macos: ">= :sonoma"

  app "Terminote.app"
end
EOF

echo "Built $CASK_PATH"
echo "Install locally with: brew install --cask $CASK_PATH"
