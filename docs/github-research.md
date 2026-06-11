# GitHub Research Notes

The app remains a lightweight popup/menu bar tool. The important correction is that the popup should use proven JSON-viewer patterns instead of a weak custom inspector.

## Projects Reviewed

### Boop

Repository: <https://github.com/IvanMathy/Boop>

Boop presents itself as a scriptable scratchpad for developers. The important product lesson is that transformations happen in an explicit editor surface, not by watching global selection state. That avoids Accessibility permission churn and avoids surprising popups.

Useful takeaways:

- One primary work surface.
- Paste/type input first, transform second.
- Developer-tool commands are explicit and discoverable.
- No automatic global selection interception as the core workflow.

### DevToysMac

Repository: <https://github.com/DevToys-app/DevToysMac>

DevToysMac uses a tool-selection model. The README shows a dedicated JSON Formatter among other tools, which implies an app shell where users intentionally pick a task and then operate inside that tool.

Useful takeaways:

- A utility should have a stable app shell, not a surprise floating popup.
- JSON formatting is one tool with a clear entry point.
- Tool list/search/navigation should come before deep settings.

### JSON Hero

Repository: <https://github.com/triggerdotdev/jsonhero-web>

JSON Hero describes multiple viewing modes: Column View, Tree View, Editor View, search, path support, keyboard accessibility, and content previews. This is the strongest reference for JSON exploration.

Useful takeaways:

- Use multiple modes: tree, columns, editor/raw.
- Search should cover keys, paths, values, and formatted values.
- Path bar/history are core navigation, not secondary details.
- Content previews are valuable only when attached to the selected value.
- Keyboard navigation matters.

### JSON Crack

Repository: <https://github.com/AykutSarac/jsoncrack.com>

JSON Crack focuses on graph/tree visualization and local processing. Its README emphasizes visualizer, format/validate, queries, export, and privacy.

Useful takeaways:

- Visualization mode should be a first-class mode, not a decoration.
- Keep processing local.
- Add query tools only when the base viewer is solid.
- Large documents need node limits and performance controls.

### JSONEditor

Repository: <https://github.com/josdejong/jsoneditor>

JSONEditor documents distinct modes: tree, code, text, and preview. Its feature list includes editing, sorting, search/highlight, undo/redo, schema validation, format/compact, repair, and large-document preview.

Useful takeaways:

- Modes should be explicit and optimized for different tasks.
- Tree mode needs real operations: expand/collapse, search highlight, copy path/value.
- Code mode needs format, compact, repair, validation.
- Preview mode is important for large JSON.

## Rebuild Direction

Keep the menu bar popup, but make the popup content behave like a real JSON browser.

Minimum viable interaction model:

1. Menu bar app with a floating popup.
2. Clipboard-first trigger, plus optional selected-text detection.
3. Parse once per input and open popup.
4. Show segmented modes: Columns, Tree, Raw.
5. Tree view supports expand/collapse all, search, copy path, copy value.
6. Detail panel shows selected path, type, preview, children, and inferred values.
7. Avoid prompting for permissions unless the user explicitly enables selected-text detection.

Avoid in the next version:

- Accessibility as a default requirement.
- Polling selected text globally.
- Surprise floating windows.
- Permission prompts during normal use.
- Settings before core browsing is excellent.
