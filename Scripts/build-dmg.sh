#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Json Lens"
APP_DIR="$ROOT_DIR/.build/${APP_NAME}.app"
DMG_ROOT="$ROOT_DIR/.build/dmg-root"
DMG_PATH="$ROOT_DIR/.build/${APP_NAME}.dmg"
RW_DMG="$ROOT_DIR/.build/${APP_NAME}-rw.dmg"

"$ROOT_DIR/Scripts/build-app.sh" >/dev/null

rm -rf "$DMG_ROOT" "$DMG_PATH" "$RW_DMG"
mkdir -p "$DMG_ROOT"
cp -R "$APP_DIR" "$DMG_ROOT/"
ln -s /Applications "$DMG_ROOT/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDRW \
  "$RW_DMG" >/dev/null

MOUNT_PATH="$(hdiutil attach -readwrite -noverify -nobrowse "$RW_DMG" | awk '/\/Volumes\// { print substr($0, index($0, "/Volumes/")); exit }')"
cleanup() {
  if [[ -n "${MOUNT_PATH:-}" ]] && [[ -d "$MOUNT_PATH" ]]; then
    hdiutil detach "$MOUNT_PATH" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT
mkdir -p "$MOUNT_PATH/.background"
cp "$ROOT_DIR/.build/assets/Install.png" "$MOUNT_PATH/.background/Install.png"

osascript <<APPLESCRIPT
tell application "Finder"
  tell disk "${APP_NAME}"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {100, 100, 800, 540}
    set theViewOptions to the icon view options of container window
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to 112
    set background picture of theViewOptions to (POSIX file "${MOUNT_PATH}/.background/Install.png")
    set position of item "${APP_NAME}.app" of container window to {170, 240}
    set position of item "Applications" of container window to {530, 240}
    close
    open
    update without registering applications
  end tell
end tell
APPLESCRIPT

sync
hdiutil detach "$MOUNT_PATH" >/dev/null
MOUNT_PATH=""
trap - EXIT

hdiutil convert "$RW_DMG" \
  -format UDZO \
  -ov \
  -o "$DMG_PATH" >/dev/null

rm -f "$RW_DMG"

echo "$DMG_PATH"
