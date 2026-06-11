import AppKit
import Combine
import SwiftUI

@MainActor
final class PopupWindowController: NSObject, NSWindowDelegate {
    private let model: AppModel
    private let settings: SettingsStore
    private var window: NSWindow?
    private var cancellables: Set<AnyCancellable> = []

    init(model: AppModel, settings: SettingsStore) {
        self.model = model
        self.settings = settings
        super.init()

        settings.objectWillChange
            .sink { [weak self] in
                Task { @MainActor in self?.applyAppearance() }
            }
            .store(in: &cancellables)
    }

    func show() {
        if window == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 980, height: 660),
                styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "Json Lens"
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.isReleasedWhenClosed = false
            window.level = .floating
            window.minSize = NSSize(width: 760, height: 460)
            window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
            window.contentViewController = NSHostingController(rootView: JsonPopupView(model: model, settings: settings))
            window.delegate = self
            applyAppearance(to: window)
            position(window)
            self.window = window
        } else if let window {
            ensureWindowIsVisible(window)
            applyAppearance(to: window)
        }

        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }

    private func position(_ window: NSWindow) {
        let screen = screenContainingMouse() ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else {
            window.center()
            return
        }

        let size = window.frame.size
        let origin = NSPoint(
            x: visibleFrame.midX - size.width / 2,
            y: visibleFrame.midY - size.height / 2
        )
        window.setFrameOrigin(clamped(origin: origin, size: size, visibleFrame: visibleFrame))
    }

    private func ensureWindowIsVisible(_ window: NSWindow) {
        let frame = window.frame
        let visibleOnAnyScreen = NSScreen.screens.contains { screen in
            screen.visibleFrame.intersects(frame)
        }

        if !visibleOnAnyScreen {
            position(window)
        }
    }

    private func screenContainingMouse() -> NSScreen? {
        let location = NSEvent.mouseLocation
        return NSScreen.screens.first { screen in
            screen.frame.contains(location)
        }
    }

    private func applyAppearance() {
        guard let window else { return }
        applyAppearance(to: window)
    }

    private func applyAppearance(to window: NSWindow) {
        window.appearance = settings.appearance.nsAppearance
    }

    private func clamped(origin: NSPoint, size: NSSize, visibleFrame: NSRect) -> NSPoint {
        NSPoint(
            x: min(max(origin.x, visibleFrame.minX), max(visibleFrame.minX, visibleFrame.maxX - size.width)),
            y: min(max(origin.y, visibleFrame.minY), max(visibleFrame.minY, visibleFrame.maxY - size.height))
        )
    }
}
