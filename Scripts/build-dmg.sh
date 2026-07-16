#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Json Lens"
APP_DIR="$ROOT_DIR/.build/${APP_NAME}.app"
DMG_ROOT="$ROOT_DIR/.build/dmg-root"
DMG_PATH="$ROOT_DIR/.build/${APP_NAME}.dmg"

"$ROOT_DIR/Scripts/build-app.sh" >/dev/null

if ! command -v create-dmg >/dev/null 2>&1; then
  echo "create-dmg is required. Install it with: brew install create-dmg" >&2
  exit 1
fi

rm -rf "$DMG_ROOT" "$DMG_PATH"
mkdir -p "$DMG_ROOT"
cp -R "$APP_DIR" "$DMG_ROOT/"

create-dmg \
  --volname "$APP_NAME" \
  --volicon "$APP_DIR/Contents/Resources/AppIcon.icns" \
  --background "$ROOT_DIR/.build/assets/Install.png" \
  --window-pos 200 150 \
  --window-size 700 440 \
  --icon-size 112 \
  --text-size 12 \
  --icon "${APP_NAME}.app" 170 240 \
  --app-drop-link 530 240 \
  --no-internet-enable \
  --format UDZO \
  "$DMG_PATH" \
  "$DMG_ROOT" >/dev/null

echo "$DMG_PATH"
