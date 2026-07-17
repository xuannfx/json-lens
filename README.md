# Json Lens

[中文文档](README.zh-CN.md)

Json Lens is a lightweight macOS menu bar JSON viewer. Copy or select JSON to open a floating browser with no Dock icon or full app window.

## Features

- Detects JSON, JSONC, JSON Lines, and common JSON text formats
- Raw, Tree, and Columns views
- Formatting, syntax highlighting, wrapping, search, expand, and collapse
- Path, type, and child-node inspector with resizable panes
- Clipboard watching, configurable global shortcut, and optional selection detection
- Light/dark appearance and four color themes

## Usage

1. Download `Json Lens.dmg` from [Releases](https://github.com/xuannfx/json-lens/releases/latest), then open it.
2. Drag `Json Lens.app` to `Applications`, then launch it.
3. Click the `{}` menu bar icon or copy JSON. With clipboard watching enabled, the viewer opens automatically.
4. The default shortcut is `Command-Shift-J`. It attempts to read JSON from the current selection or clipboard.
5. Use the settings icon in the popup header to change the shortcut, detection behavior, appearance, and theme.

Use `Tree` for hierarchy, `Raw` for line numbers, syntax highlighting, and wrapping, and `Columns` for step-by-step drilling. Press `Esc` to close the popup.

## Permissions and Gatekeeper

- **Accessibility** is only used when selected-text detection is enabled or another app's selected text needs to be read. Clipboard viewing does not require it.
- Public builds are currently ad-hoc signed. On first launch after downloading, macOS may show an unidentified-developer warning. In Finder, Control-click the app, choose **Open**, and confirm once.

## Development and Build

```bash
swift run JsonLens

# Build app
Scripts/build-app.sh
open ".build/Json Lens.app"

# Build DMG (install once)
python3 -m pip install --user dmgbuild
Scripts/build-dmg.sh
open ".build/Json Lens.dmg"
```

## License

[MIT License](LICENSE)
