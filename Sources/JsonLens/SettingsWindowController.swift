import AppKit
import Combine
import SwiftUI

@MainActor
final class SettingsWindowController {
    private let settings: SettingsStore
    private var window: NSWindow?
    private var cancellables: Set<AnyCancellable> = []

    init(settings: SettingsStore) {
        self.settings = settings

        settings.objectWillChange
            .sink { [weak self] in
                Task { @MainActor in self?.applyAppearance() }
            }
            .store(in: &cancellables)
    }

    func show() {
        if window == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 560, height: 620),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Json Lens Settings"
            window.isReleasedWhenClosed = false
            window.minSize = NSSize(width: 520, height: 520)
            window.contentViewController = NSHostingController(rootView: SettingsView(settings: settings))
            applyAppearance(to: window)
            window.center()
            self.window = window
        }

        if let window {
            applyAppearance(to: window)
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func applyAppearance() {
        guard let window else { return }
        applyAppearance(to: window)
    }

    private func applyAppearance(to window: NSWindow) {
        window.appearance = settings.appearance.nsAppearance
    }
}
