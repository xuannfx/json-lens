import AppKit
import Combine
import JsonLensCore

private struct DetectedInput {
    let document: JSONDocument
    let signature: String
}

private struct PasteboardSnapshot {
    let items: [[NSPasteboard.PasteboardType: Data]]

    static func capture(from pasteboard: NSPasteboard) -> PasteboardSnapshot {
        let items = pasteboard.pasteboardItems?.map { item in
            item.types.reduce(into: [NSPasteboard.PasteboardType: Data]()) { result, type in
                result[type] = item.data(forType: type)
            }
        } ?? []
        return PasteboardSnapshot(items: items)
    }

    func restore(to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        let pasteboardItems = items.map { itemData in
            let item = NSPasteboardItem()
            for (type, data) in itemData {
                item.setData(data, forType: type)
            }
            return item
        }
        if !pasteboardItems.isEmpty {
            pasteboard.writeObjects(pasteboardItems)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let settings = SettingsStore()
    private let model = AppModel()
    private let selectionReader = SelectionReader()

    private var statusItem: NSStatusItem?
    private var popupController: PopupWindowController?
    private var settingsController: SettingsWindowController?
    private var hotKeyManager: HotKeyManager?
    private var clipboardTimer: Timer?
    private var selectionTimer: Timer?
    private var cancellables: Set<AnyCancellable> = []

    private var lastClipboardChangeCount = NSPasteboard.general.changeCount
    private var lastPresentedSignature: String?
    private var pendingSelectionText: String?
    private var pendingSelectionSignature: String?
    private var pendingSelectionUpdatedAt = Date.distantPast
    private var suppressClipboardPollingUntil = Date.distantPast

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupTimers()
        observeSettings()
        configureHotKey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardTimer?.invalidate()
        selectionTimer?.invalidate()
        hotKeyManager?.unregister()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        populateMenu(menu)
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            let image = NSImage(systemSymbolName: "curlybraces.square", accessibilityDescription: "Json Lens")
            image?.isTemplate = true
            button.image = image
            button.title = image == nil ? "{}" : ""
            button.toolTip = "Json Lens"
        }

        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        statusItem = item
    }

    private func populateMenu(_ menu: NSMenu) {
        menu.removeAllItems()

        addMenuItem("Open Clipboard", action: #selector(openClipboardFromMenu), to: menu)
        let selectionItem = addMenuItem("Open Selection", action: #selector(openSelection), to: menu)
        selectionItem.keyEquivalent = "j"
        selectionItem.keyEquivalentModifierMask = [.command, .shift]

        menu.addItem(.separator())

        let clipboardItem = addMenuItem("Watch Clipboard", action: #selector(toggleClipboardWatch), to: menu)
        clipboardItem.state = settings.monitorClipboard ? .on : .off

        let selectionWatchItem = addMenuItem("Auto Detect Selection", action: #selector(toggleSelectionWatch), to: menu)
        selectionWatchItem.state = settings.autoDetectSelection ? .on : .off

        let hotkeyItem = addMenuItem("Hotkey Command-Shift-J", action: #selector(toggleHotKey), to: menu)
        hotkeyItem.state = settings.enableHotkey ? .on : .off

        menu.addItem(.separator())

        addAppearanceMenu(to: menu)
        addThemeMenu(to: menu)

        menu.addItem(.separator())

        let permissionTitle = SelectionReader.isTrusted()
            ? "Accessibility: Allowed"
            : "Enable Accessibility..."
        let permissionItem = addMenuItem(permissionTitle, action: #selector(requestAccessibility), to: menu)
        permissionItem.isEnabled = !SelectionReader.isTrusted()

        addMenuItem("Settings...", action: #selector(openSettings), to: menu)

        menu.addItem(.separator())
        addMenuItem("Quit Json Lens", action: #selector(quit), to: menu)
    }

    @discardableResult
    private func addMenuItem(_ title: String, action: Selector, to menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
        return item
    }

    private func addAppearanceMenu(to menu: NSMenu) {
        let item = NSMenuItem(title: "Appearance", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "Appearance")

        for appearance in LensAppearance.allCases {
            let child = NSMenuItem(title: appearance.displayName, action: #selector(setAppearance), keyEquivalent: "")
            child.target = self
            child.representedObject = appearance.rawValue
            child.state = settings.appearance == appearance ? .on : .off
            submenu.addItem(child)
        }

        item.submenu = submenu
        menu.addItem(item)
    }

    private func addThemeMenu(to menu: NSMenu) {
        let item = NSMenuItem(title: "Color Theme", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "Color Theme")

        for theme in LensColorTheme.allCases {
            let child = NSMenuItem(title: theme.displayName, action: #selector(setColorTheme), keyEquivalent: "")
            child.target = self
            child.representedObject = theme.rawValue
            child.state = settings.colorTheme == theme ? .on : .off
            submenu.addItem(child)
        }

        item.submenu = submenu
        menu.addItem(item)
    }

    private func setupTimers() {
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.pollClipboard() }
        }

        selectionTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.pollSelection() }
        }
    }

    private func observeSettings() {
        settings.$enableHotkey
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in self?.configureHotKey() }
            }
            .store(in: &cancellables)
    }

    private func configureHotKey() {
        hotKeyManager?.unregister()
        hotKeyManager = nil

        guard settings.enableHotkey else {
            return
        }

        let manager = HotKeyManager { [weak self] in
            Task { @MainActor in self?.openSelection() }
        }
        manager.register()
        hotKeyManager = manager
    }

    private func pollClipboard() {
        guard settings.monitorClipboard else {
            return
        }
        guard Date() >= suppressClipboardPollingUntil else {
            lastClipboardChangeCount = NSPasteboard.general.changeCount
            return
        }

        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastClipboardChangeCount else {
            return
        }
        lastClipboardChangeCount = pasteboard.changeCount

        _ = openClipboardDocument(auto: true)
    }

    private func pollSelection() {
        guard settings.autoDetectSelection,
              SelectionReader.isTrusted(),
              NSEvent.pressedMouseButtons == 0,
              let text = selectionReader.selectedText(maxCharacters: settings.maxCharacters)
        else {
            pendingSelectionText = nil
            pendingSelectionSignature = nil
            return
        }

        let now = Date()
        let signature = makeSignature(text)
        guard signature != lastPresentedSignature else {
            return
        }

        if signature != pendingSelectionSignature {
            pendingSelectionText = text
            pendingSelectionSignature = signature
            pendingSelectionUpdatedAt = now
            return
        }

        guard now.timeIntervalSince(pendingSelectionUpdatedAt) >= settings.selectionStableDelay,
              let pendingSelectionText
        else {
            return
        }

        self.pendingSelectionText = nil
        pendingSelectionSignature = nil
        present(text: pendingSelectionText, sourceKind: .selection, description: "Selection", auto: true)
    }

    @discardableResult
    private func openClipboardDocument(auto: Bool) -> Bool {
        let pasteboardChangeCount = NSPasteboard.general.changeCount
        let candidates = ClipboardReader.candidates(
            maxCharacters: settings.maxCharacters,
            includeFileURLs: settings.includeFileURLs
        )

        for candidate in candidates {
            if present(
                text: candidate.text,
                sourceKind: candidate.sourceKind,
                description: candidate.description,
                auto: auto
            ) {
                lastClipboardChangeCount = pasteboardChangeCount
                return true
            }
        }

        if !auto {
            model.statusText = "No JSON found in clipboard"
            showPopup()
        }
        return false
    }

    @discardableResult
    private func present(text: String, sourceKind: JSONSourceKind, description: String, auto: Bool) -> Bool {
        guard let input = detectedInput(text: text, sourceKind: sourceKind, description: description) else {
            return false
        }
        return present(input, auto: auto)
    }

    private func detectedInput(text: String, sourceKind: JSONSourceKind, description: String) -> DetectedInput? {
        guard let document = JSONDetector.detect(
            text,
            sourceKind: sourceKind,
            sourceDescription: description,
            options: JSONDetectionOptions(maxCharacters: settings.maxCharacters)
        ) else {
            return nil
        }

        return DetectedInput(
            document: document,
            signature: makeSignature(document.normalizedText)
        )
    }

    @discardableResult
    private func present(_ input: DetectedInput, auto: Bool) -> Bool {
        if auto, input.signature == lastPresentedSignature {
            return true
        }

        lastPresentedSignature = input.signature
        model.show(input.document)
        showPopup()
        return true
    }

    private func showPopup() {
        if popupController == nil {
            popupController = PopupWindowController(model: model, settings: settings)
        }
        popupController?.show()
    }

    private func makeSignature(_ text: String) -> String {
        "\(text.count):\(text.hashValue)"
    }

    @objc private func openClipboardFromMenu() {
        _ = openClipboardDocument(auto: false)
    }

    @objc private func openSelection() {
        Task { @MainActor in
            await openSelectionFromUserAction()
        }
    }

    private func openSelectionFromUserAction() async {
        let pasteboard = NSPasteboard.general
        let pasteboardChangeCount = pasteboard.changeCount
        let clipboardIsFresh = pasteboardChangeCount != lastClipboardChangeCount
        let clipboardCandidate = ClipboardReader.candidates(
            maxCharacters: settings.maxCharacters,
            includeFileURLs: settings.includeFileURLs
        )
        .lazy
        .compactMap { candidate in
            self.detectedInput(
                text: candidate.text,
                sourceKind: candidate.sourceKind,
                description: candidate.description
            )
        }
        .first

        if clipboardIsFresh,
           let clipboardCandidate,
           present(clipboardCandidate, auto: false) {
            lastClipboardChangeCount = pasteboardChangeCount
            return
        }

        let axSelectionCandidate = selectionReader.selectedText(maxCharacters: settings.maxCharacters).flatMap {
            detectedInput(text: $0, sourceKind: .selection, description: "Selection")
        }

        if let axSelectionCandidate,
           axSelectionCandidate.signature != lastPresentedSignature,
           present(axSelectionCandidate, auto: false) {
            return
        }

        let copiedSelectionCandidate = await copiedSelectionCandidate(
            originalPasteboardChangeCount: pasteboardChangeCount
        )

        if let copiedSelectionCandidate,
           copiedSelectionCandidate.signature != lastPresentedSignature,
           present(copiedSelectionCandidate, auto: false) {
            return
        }

        if let clipboardCandidate,
           clipboardCandidate.signature != lastPresentedSignature,
           present(clipboardCandidate, auto: false) {
            lastClipboardChangeCount = pasteboardChangeCount
            return
        }

        if let axSelectionCandidate,
           present(axSelectionCandidate, auto: false) {
            return
        }

        if let copiedSelectionCandidate,
           present(copiedSelectionCandidate, auto: false) {
            return
        }

        if let clipboardCandidate,
           present(clipboardCandidate, auto: false) {
            lastClipboardChangeCount = pasteboardChangeCount
            return
        }

        model.statusText = "No JSON found in selection or clipboard"
        showPopup()
    }

    private func copiedSelectionCandidate(originalPasteboardChangeCount: Int) async -> DetectedInput? {
        guard SelectionReader.isTrusted() else {
            return nil
        }

        let pasteboard = NSPasteboard.general
        let snapshot = PasteboardSnapshot.capture(from: pasteboard)

        guard selectionReader.copySelectedTextToPasteboard() else {
            return nil
        }
        suppressClipboardPollingUntil = Date().addingTimeInterval(1.0)

        try? await Task.sleep(nanoseconds: 160_000_000)

        guard pasteboard.changeCount != originalPasteboardChangeCount else {
            return nil
        }
        defer {
            snapshot.restore(to: pasteboard)
            lastClipboardChangeCount = pasteboard.changeCount
            suppressClipboardPollingUntil = Date().addingTimeInterval(0.35)
        }

        let text = pasteboard.string(forType: .string)
        return text.flatMap {
            detectedInput(text: $0, sourceKind: .selection, description: "Selection")
        }
    }

    @objc private func toggleClipboardWatch() {
        settings.monitorClipboard.toggle()
    }

    @objc private func toggleSelectionWatch() {
        settings.autoDetectSelection.toggle()
        if settings.autoDetectSelection, !SelectionReader.isTrusted() {
            settings.autoDetectSelection = false
            _ = SelectionReader.isTrusted(prompt: true)
        }
    }

    @objc private func toggleHotKey() {
        settings.enableHotkey.toggle()
    }

    @objc private func setAppearance(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let appearance = LensAppearance(rawValue: rawValue)
        else {
            return
        }
        settings.appearance = appearance
    }

    @objc private func setColorTheme(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let colorTheme = LensColorTheme(rawValue: rawValue)
        else {
            return
        }
        settings.colorTheme = colorTheme
    }

    @objc private func requestAccessibility() {
        _ = SelectionReader.isTrusted(prompt: true)
    }

    @objc private func openSettings() {
        if settingsController == nil {
            settingsController = SettingsWindowController(settings: settings)
        }
        settingsController?.show()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
