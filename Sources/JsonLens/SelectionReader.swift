import AppKit
import ApplicationServices
import Carbon
import Foundation

final class SelectionReader {
    static func isTrusted(prompt: Bool = false) -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([key: prompt] as CFDictionary)
    }

    func selectedText(maxCharacters: Int) -> String? {
        guard Self.isTrusted(), let app = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        if let bundleIdentifier = Bundle.main.bundleIdentifier,
           app.bundleIdentifier == bundleIdentifier {
            return nil
        }

        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var focusedObject: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXFocusedUIElementAttribute as CFString, &focusedObject) == .success,
              let focusedObject,
              CFGetTypeID(focusedObject) == AXUIElementGetTypeID()
        else {
            return nil
        }

        let focused = focusedObject as! AXUIElement
        var selectedObject: CFTypeRef?
        guard AXUIElementCopyAttributeValue(focused, kAXSelectedTextAttribute as CFString, &selectedObject) == .success,
              let text = selectedObject as? String,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              text.count <= maxCharacters
        else {
            return nil
        }

        return text
    }

    func copySelectedTextToPasteboard() -> Bool {
        guard Self.isTrusted(), let app = NSWorkspace.shared.frontmostApplication else {
            return false
        }
        if let bundleIdentifier = Bundle.main.bundleIdentifier,
           app.bundleIdentifier == bundleIdentifier {
            return false
        }

        let source = CGEventSource(stateID: .hidSystemState)
        guard let keyDown = CGEvent(
            keyboardEventSource: source,
            virtualKey: CGKeyCode(kVK_ANSI_C),
            keyDown: true
        ),
        let keyUp = CGEvent(
            keyboardEventSource: source,
            virtualKey: CGKeyCode(kVK_ANSI_C),
            keyDown: false
        )
        else {
            return false
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }
}
