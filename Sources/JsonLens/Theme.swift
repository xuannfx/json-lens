import AppKit
import SwiftUI

enum LensAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    var nsAppearance: NSAppearance? {
        switch self {
        case .system:
            return nil
        case .light:
            return NSAppearance(named: .aqua)
        case .dark:
            return NSAppearance(named: .darkAqua)
        }
    }
}

enum LensColorTheme: String, CaseIterable, Identifiable {
    case quartz
    case github
    case solarized
    case prism

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .quartz:
            return "Quartz"
        case .github:
            return "GitHub"
        case .solarized:
            return "Solarized"
        case .prism:
            return "Prism"
        }
    }

    var subtitle: String {
        switch self {
        case .quartz:
            return "Clean macOS neutral"
        case .github:
            return "Familiar code review colors"
        case .solarized:
            return "Low-glare warm contrast"
        case .prism:
            return "Sharper high-signal tokens"
        }
    }

    var palette: LensPalette {
        switch self {
        case .quartz:
            return LensPalette(
                window: .init(0xF5F7FB, 0x12131A),
                pane: .init(0xECEFF6, 0x1B1D27),
                code: .init(0xFFFFFF, 0x0E1016),
                border: .init(0xD3D9E6, 0x343844, lightAlpha: 0.92, darkAlpha: 0.9),
                selected: .init(0xD8ECF2, 0x154D57, lightAlpha: 0.95, darkAlpha: 0.9),
                codeSelected: .init(0xE3F4F8, 0x185864, lightAlpha: 1, darkAlpha: 0.95),
                hover: .init(0xE5EAF3, 0x242735, lightAlpha: 0.86, darkAlpha: 0.88),
                gutter: .init(0xEEF2F8, 0x171924),
                plain: .init(0x202638, 0xEEF2F7),
                key: .init(0x285CC4, 0x7AB7FF),
                string: .init(0x087765, 0x7ADFC2),
                number: .init(0xB1540F, 0xFFBE72),
                bool: .init(0x8347B8, 0xD7B1FF),
                null: .init(0xC93261, 0xFF8CAF),
                punctuation: .init(0x6D7482, 0xA6ADBA),
                object: .init(0x285CC4, 0x7AB7FF),
                array: .init(0x087B8C, 0x65D7E6),
                accent: .init(0x087B8C, 0x65D7E6)
            )
        case .github:
            return LensPalette(
                window: .init(0xF6F8FA, 0x0D1117),
                pane: .init(0xFFFFFF, 0x161B22),
                code: .init(0xFFFFFF, 0x0D1117),
                border: .init(0xD0D7DE, 0x30363D),
                selected: .init(0xDDF4FF, 0x1F6FEB, lightAlpha: 0.9, darkAlpha: 0.36),
                codeSelected: .init(0xDDF4FF, 0x1F6FEB, lightAlpha: 0.96, darkAlpha: 0.44),
                hover: .init(0xF3F4F6, 0x21262D, lightAlpha: 0.9, darkAlpha: 0.82),
                gutter: .init(0xF6F8FA, 0x161B22),
                plain: .init(0x24292F, 0xC9D1D9),
                key: .init(0x0969DA, 0x79C0FF),
                string: .init(0x0A7F42, 0xA5D6A7),
                number: .init(0x953800, 0xFFA657),
                bool: .init(0x8250DF, 0xD2A8FF),
                null: .init(0xCF222E, 0xFF7B72),
                punctuation: .init(0x57606A, 0x8B949E),
                object: .init(0x0969DA, 0x79C0FF),
                array: .init(0x0A7F83, 0x56D4DD),
                accent: .init(0x0969DA, 0x58A6FF)
            )
        case .solarized:
            return LensPalette(
                window: .init(0xFDF6E3, 0x002B36),
                pane: .init(0xEEE8D5, 0x073642),
                code: .init(0xFFFBEC, 0x00212B),
                border: .init(0xD8D0B7, 0x31535D, lightAlpha: 0.9, darkAlpha: 0.9),
                selected: .init(0xD7E9D0, 0x124852, lightAlpha: 0.82, darkAlpha: 0.9),
                codeSelected: .init(0xD7E9D0, 0x164F5A, lightAlpha: 0.9, darkAlpha: 0.94),
                hover: .init(0xF3EBCF, 0x0B3A45, lightAlpha: 0.9, darkAlpha: 0.92),
                gutter: .init(0xF6EFD8, 0x07323D),
                plain: .init(0x586E75, 0x93A1A1),
                key: .init(0x268BD2, 0x5EC4FF),
                string: .init(0x2AA198, 0x7AD7CB),
                number: .init(0xB58900, 0xF2C94C),
                bool: .init(0x6C71C4, 0xB9A7FF),
                null: .init(0xDC322F, 0xFF8F85),
                punctuation: .init(0x839496, 0x657B83),
                object: .init(0x268BD2, 0x5EC4FF),
                array: .init(0x2AA198, 0x7AD7CB),
                accent: .init(0x268BD2, 0x5EC4FF)
            )
        case .prism:
            return LensPalette(
                window: .init(0xF8F7FF, 0x101014),
                pane: .init(0xFFFFFF, 0x181820),
                code: .init(0xFFFFFF, 0x0B0B10),
                border: .init(0xD8D4E8, 0x35313F),
                selected: .init(0xE5F0FF, 0x263D5B, lightAlpha: 0.94, darkAlpha: 0.9),
                codeSelected: .init(0xEEF5FF, 0x233A56, lightAlpha: 1, darkAlpha: 1),
                hover: .init(0xF0EEF9, 0x24232D, lightAlpha: 0.92, darkAlpha: 0.9),
                gutter: .init(0xF1F0FA, 0x16161D),
                plain: .init(0x17171D, 0xF2F1F5),
                key: .init(0x006ADC, 0x4DB7FF),
                string: .init(0x008A65, 0x61D394),
                number: .init(0xB85500, 0xFFB15D),
                bool: .init(0x7A3FB2, 0xC9A2FF),
                null: .init(0xD12D62, 0xFF7EAF),
                punctuation: .init(0x69707D, 0xA5A8B6),
                object: .init(0x006ADC, 0x4DB7FF),
                array: .init(0x008A8A, 0x55D6D6),
                accent: .init(0x006ADC, 0x4DB7FF)
            )
        }
    }
}

struct LensPalette {
    let window: ThemedColor
    let pane: ThemedColor
    let code: ThemedColor
    let border: ThemedColor
    let selected: ThemedColor
    let codeSelected: ThemedColor
    let hover: ThemedColor
    let gutter: ThemedColor
    let plain: ThemedColor
    let key: ThemedColor
    let string: ThemedColor
    let number: ThemedColor
    let bool: ThemedColor
    let null: ThemedColor
    let punctuation: ThemedColor
    let object: ThemedColor
    let array: ThemedColor
    let accent: ThemedColor
}

private struct LensPaletteKey: EnvironmentKey {
    static let defaultValue = LensColorTheme.quartz.palette
}

extension EnvironmentValues {
    var lensPalette: LensPalette {
        get { self[LensPaletteKey.self] }
        set { self[LensPaletteKey.self] = newValue }
    }
}

struct ThemedColor {
    let light: UInt32
    let dark: UInt32
    let lightAlpha: Double
    let darkAlpha: Double

    init(_ light: UInt32, _ dark: UInt32, lightAlpha: Double = 1, darkAlpha: Double = 1) {
        self.light = light
        self.dark = dark
        self.lightAlpha = lightAlpha
        self.darkAlpha = darkAlpha
    }

    var color: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return nsColor(hex: isDark ? dark : light, alpha: isDark ? darkAlpha : lightAlpha)
        })
    }
}

private func nsColor(hex: UInt32, alpha: Double) -> NSColor {
    let red = CGFloat((hex >> 16) & 0xFF) / 255
    let green = CGFloat((hex >> 8) & 0xFF) / 255
    let blue = CGFloat(hex & 0xFF) / 255
    return NSColor(calibratedRed: red, green: green, blue: blue, alpha: CGFloat(alpha))
}
