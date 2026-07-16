# Json Lens

Json Lens is a lightweight macOS menu bar popup for opening JSON-like text from the clipboard or current selection and browsing it visually.

The current UI is intentionally popup-first: no normal app window, no Dock icon, and no surprise Accessibility prompt during normal clipboard use.

## Features

- Detection for JSON, JSONC comments/trailing commas, JSON Lines, Base64 JSON, URL-encoded JSON, Markdown code fences, and embedded JSON
- Normalized `JSONDocument` model with flattened tree paths
- Menu bar utility with floating popup
- Popup opens on the screen containing the mouse and uses stable floating-window behavior for multi-display setups
- Appearance switcher with System, Light, and Dark modes
- Multiple color themes: Quartz, GitHub, Solarized, and Prism
- Theme switching from both the status bar menu and Settings
- Clipboard watch: copy JSON and the popup opens
- Optional selected-text detection through Accessibility
- Configurable global shortcut opens selected text when Accessibility is available, otherwise opens clipboard
- Tree view first, with expand/collapse
- Tree rows wrap long values instead of forcing the panel wider
- Raw formatted JSON view with line numbers, syntax color, and optional word wrap
- Raw syntax highlighting uses the selected theme for keys, strings, numbers, booleans, nulls, and punctuation
- Raw mode includes a compact color legend for token meanings
- Raw rows are clickable and sync the inspector to the matching JSON path
- Resizable split view between browser and inspector panels
- Inspector breadcrumb and parent navigation for drilling back up after selecting children
- Inspector panel scrolls vertically as one surface, including metadata and children
- Column view inspired by macOS Finder and JSON Hero
- Search across keys, paths, and values
- Inspector with selected path, type, preview, children, and inferred string content

## Run

```bash
swift run JsonLens
```

## Build App

```bash
Scripts/build-app.sh
open ".build/Json Lens.app"
```

## Build DMG

```bash
Scripts/build-dmg.sh
open ".build/Json Lens.dmg"
```

The DMG contains a branded app icon, a drag-and-drop guide, and an `Applications` shortcut.

## Signed Distribution

The default build is ad-hoc signed for local development. Gatekeeper can warn when an ad-hoc app is downloaded from the internet. For a public release, sign with a paid Apple Developer Program certificate and notarize the DMG:

```bash
export DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)"
Scripts/build-dmg.sh

# Create this once with xcrun notarytool store-credentials, then use its profile name.
export NOTARY_PROFILE="json-lens-notary"
Scripts/notarize-dmg.sh
```

After notarization, distribute the stapled `.build/Json Lens.dmg`.

## License

Json Lens is released under the [MIT License](LICENSE).

## References

Research notes for the next UI are in `docs/github-research.md`.

- [Boop](https://github.com/IvanMathy/Boop): lightweight developer scratchpad model.
- [DevToysMac](https://github.com/DevToys-app/DevToysMac): native macOS developer utility and JSON formatter entry point.
- [JSON Hero](https://github.com/triggerdotdev/jsonhero-web): tree/search/path-oriented JSON exploration ideas.
