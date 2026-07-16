import AppKit
import SwiftUI

struct ShortcutRecorder: NSViewRepresentable {
    let shortcut: GlobalShortcut
    let onRecord: (GlobalShortcut) -> Void

    func makeNSView(context: Context) -> ShortcutRecorderButton {
        let button = ShortcutRecorderButton()
        button.shortcut = shortcut
        button.onRecord = onRecord
        return button
    }

    func updateNSView(_ nsView: ShortcutRecorderButton, context: Context) {
        nsView.shortcut = shortcut
        nsView.onRecord = onRecord
    }
}

final class ShortcutRecorderButton: NSButton {
    var shortcut = GlobalShortcut.default {
        didSet { updateTitle() }
    }
    var onRecord: ((GlobalShortcut) -> Void)?
    private var isRecording = false {
        didSet { updateTitle() }
    }

    init() {
        super.init(frame: .zero)
        bezelStyle = .rounded
        controlSize = .regular
        font = .monospacedSystemFont(ofSize: 13, weight: .medium)
        target = self
        action = #selector(beginRecording)
        updateTitle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    @objc private func beginRecording() {
        isRecording = true
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        if event.keyCode == 53 {
            isRecording = false
            return
        }

        guard let shortcut = GlobalShortcut(event: event) else {
            NSSound.beep()
            return
        }

        self.shortcut = shortcut
        isRecording = false
        onRecord?(shortcut)
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        return super.resignFirstResponder()
    }

    private func updateTitle() {
        title = isRecording ? "Press shortcut" : shortcut.displayName
        toolTip = isRecording ? "Press a shortcut with Command, Option, or Control" : "Click to record a shortcut"
    }
}
