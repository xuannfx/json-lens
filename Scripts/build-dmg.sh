#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Json Lens"
APP_DIR="$ROOT_DIR/.build/${APP_NAME}.app"
DMG_PATH="$ROOT_DIR/.build/${APP_NAME}.dmg"

"$ROOT_DIR/Scripts/build-app.sh" >/dev/null

if ! python3 -c 'import dmgbuild' >/dev/null 2>&1; then
  echo "dmgbuild is required. Install it with: python3 -m pip install --user dmgbuild" >&2
  exit 1
fi

rm -f "$DMG_PATH"

python3 -m dmgbuild \
  -s "$ROOT_DIR/Scripts/dmg-settings.py" \
  -D "application=$APP_DIR" \
  -D "background=$ROOT_DIR/.build/assets/Install.png" \
  -D "icon=$APP_DIR/Contents/Resources/AppIcon.icns" \
  "$APP_NAME" \
  "$DMG_PATH" >/dev/null

echo "$DMG_PATH"
