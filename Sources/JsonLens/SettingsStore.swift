import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    private enum Keys {
        static let monitorClipboard = "monitorClipboard"
        static let autoDetectSelection = "autoDetectSelection"
        static let includeFileURLs = "includeFileURLs"
        static let enableHotkey = "enableHotkey"
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let maxCharacters = "maxCharacters"
        static let selectionStableDelay = "selectionStableDelay"
        static let appearance = "appearance"
        static let colorTheme = "colorTheme"
    }

    private let defaults: UserDefaults
    private var appearanceValue: LensAppearance
    private var colorThemeValue: LensColorTheme

    @Published var monitorClipboard: Bool {
        didSet { defaults.set(monitorClipboard, forKey: Keys.monitorClipboard) }
    }

    @Published var autoDetectSelection: Bool {
        didSet { defaults.set(autoDetectSelection, forKey: Keys.autoDetectSelection) }
    }

    @Published var includeFileURLs: Bool {
        didSet { defaults.set(includeFileURLs, forKey: Keys.includeFileURLs) }
    }

    @Published var enableHotkey: Bool {
        didSet { defaults.set(enableHotkey, forKey: Keys.enableHotkey) }
    }

    @Published var hotkey: GlobalShortcut {
        didSet {
            defaults.set(Int(hotkey.keyCode), forKey: Keys.hotkeyKeyCode)
            defaults.set(Int(hotkey.modifiers), forKey: Keys.hotkeyModifiers)
        }
    }

    @Published var maxCharacters: Int {
        didSet { defaults.set(maxCharacters, forKey: Keys.maxCharacters) }
    }

    @Published var selectionStableDelay: Double {
        didSet { defaults.set(selectionStableDelay, forKey: Keys.selectionStableDelay) }
    }

    var appearance: LensAppearance {
        get { appearanceValue }
        set {
            guard newValue != appearanceValue else { return }
            objectWillChange.send()
            appearanceValue = newValue
            defaults.set(newValue.rawValue, forKey: Keys.appearance)
        }
    }

    var colorTheme: LensColorTheme {
        get { colorThemeValue }
        set {
            guard newValue != colorThemeValue else { return }
            objectWillChange.send()
            colorThemeValue = newValue
            defaults.set(newValue.rawValue, forKey: Keys.colorTheme)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        monitorClipboard = defaults.object(forKey: Keys.monitorClipboard) as? Bool ?? true
        autoDetectSelection = defaults.object(forKey: Keys.autoDetectSelection) as? Bool ?? false
        includeFileURLs = defaults.object(forKey: Keys.includeFileURLs) as? Bool ?? true
        enableHotkey = defaults.object(forKey: Keys.enableHotkey) as? Bool ?? true
        let keyCode = defaults.object(forKey: Keys.hotkeyKeyCode) as? Int
        let modifiers = defaults.object(forKey: Keys.hotkeyModifiers) as? Int
        let storedHotkey = GlobalShortcut(
            keyCode: UInt32(keyCode ?? Int(GlobalShortcut.default.keyCode)),
            modifiers: UInt32(modifiers ?? Int(GlobalShortcut.default.modifiers))
        )
        hotkey = storedHotkey.isValid ? storedHotkey : .default
        maxCharacters = defaults.object(forKey: Keys.maxCharacters) as? Int ?? 300_000
        selectionStableDelay = defaults.object(forKey: Keys.selectionStableDelay) as? Double ?? 0.9
        appearanceValue = Self.storedAppearance(in: defaults)
        colorThemeValue = Self.storedColorTheme(in: defaults)
    }

    nonisolated static func storedAppearance(in defaults: UserDefaults = .standard) -> LensAppearance {
        guard let rawValue = defaults.string(forKey: Keys.appearance),
              let appearance = LensAppearance(rawValue: rawValue)
        else {
            return .system
        }
        return appearance
    }

    nonisolated static func storedColorTheme(in defaults: UserDefaults = .standard) -> LensColorTheme {
        guard let rawValue = defaults.string(forKey: Keys.colorTheme),
              let colorTheme = LensColorTheme(rawValue: rawValue)
        else {
            return .quartz
        }
        return colorTheme
    }
}
