#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Json Lens"
BUNDLE_ID="dev.local.JsonLens"
BUILD_DIR="$ROOT_DIR/.build/release"
APP_DIR="$ROOT_DIR/.build/${APP_NAME}.app"
ASSET_DIR="$ROOT_DIR/.build/assets"
SIGNING_IDENTITY="${DEVELOPER_ID_APPLICATION:--}"

cd "$ROOT_DIR"
swift build -c release

rm -rf "$APP_DIR" "$ASSET_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BUILD_DIR/JsonLens" "$APP_DIR/Contents/MacOS/JsonLens"
swift "$ROOT_DIR/Scripts/generate-assets.swift" "$ASSET_DIR"
/usr/bin/iconutil -c icns "$ASSET_DIR/AppIcon.iconset" -o "$APP_DIR/Contents/Resources/AppIcon.icns"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>JsonLens</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.2.1</string>
  <key>CFBundleVersion</key>
  <string>3</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
PLIST

SIGNING_ARGS=(--force --deep --sign "$SIGNING_IDENTITY")
if [[ "$SIGNING_IDENTITY" != "-" ]]; then
  SIGNING_ARGS+=(--options runtime --timestamp)
fi
/usr/bin/codesign "${SIGNING_ARGS[@]}" "$APP_DIR" >/dev/null
echo "$APP_DIR"
