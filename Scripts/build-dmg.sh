#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Json Lens"
APP_DIR="$ROOT_DIR/.build/${APP_NAME}.app"
DMG_ROOT="$ROOT_DIR/.build/dmg-root"
DMG_PATH="$ROOT_DIR/.build/${APP_NAME}.dmg"

"$ROOT_DIR/Scripts/build-app.sh" >/dev/null

rm -rf "$DMG_ROOT" "$DMG_PATH"
mkdir -p "$DMG_ROOT"
cp -R "$APP_DIR" "$DMG_ROOT/"
ln -s /Applications "$DMG_ROOT/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

echo "$DMG_PATH"
