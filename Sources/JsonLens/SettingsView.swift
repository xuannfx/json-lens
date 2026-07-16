import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @State private var accessibilityAllowed = SelectionReader.isTrusted()

    var body: some View {
        let palette = settings.colorTheme.palette

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header(palette: palette)

                SettingsSection(title: "Appearance", palette: palette) {
                    Picker("Appearance", selection: $settings.appearance) {
                        ForEach(LensAppearance.allCases) { appearance in
                            Text(appearance.displayName).tag(appearance)
                        }
                    }
                    .pickerStyle(.segmented)

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ],
                        spacing: 10
                    ) {
                        ForEach(LensColorTheme.allCases) { theme in
                            Button {
                                settings.colorTheme = theme
                            } label: {
                                ThemeTile(
                                    theme: theme,
                                    isSelected: settings.colorTheme == theme
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                SettingsSection(title: "Detection", palette: palette) {
                    Toggle("Watch clipboard", isOn: $settings.monitorClipboard)
                    Toggle("Auto detect selected text", isOn: $settings.autoDetectSelection)
                    Toggle("Read copied JSON files", isOn: $settings.includeFileURLs)
                    HStack {
                        Toggle("Enable global shortcut", isOn: $settings.enableHotkey)
                        Spacer()
                        ShortcutRecorder(shortcut: settings.hotkey) { shortcut in
                            settings.hotkey = shortcut
                        }
                        .frame(width: 130, height: 28)
                        .disabled(!settings.enableHotkey)
                    }
                    Text("Click the shortcut to record. Command, Option, or Control is required.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                SettingsSection(title: "Limits", palette: palette) {
                    Stepper(value: $settings.maxCharacters, in: 20_000...2_000_000, step: 20_000) {
                        Text("Max input: \(settings.maxCharacters.formatted()) chars")
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Selection stable delay: \(settings.selectionStableDelay, specifier: "%.1f")s")
                        Slider(value: $settings.selectionStableDelay, in: 0.5...3.0, step: 0.1)
                    }
                }

                SettingsSection(title: "Permission", palette: palette) {
                    HStack {
                        Label(
                            accessibilityAllowed ? "Accessibility allowed" : "Accessibility optional",
                            systemImage: accessibilityAllowed ? "checkmark.seal.fill" : "lock"
                        )
                        .foregroundColor(accessibilityAllowed ? palette.string.color : Color.secondary)

                        Spacer()

                        Button("Request") {
                            _ = SelectionReader.isTrusted(prompt: true)
                            refreshPermission()
                        }
                    }
                }
            }
            .padding(22)
        }
        .frame(width: 560, height: 620)
        .background(palette.window.color)
        .preferredColorScheme(settings.appearance.colorScheme)
        .onAppear(perform: refreshPermission)
    }

    private func header(palette: LensPalette) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(palette.accent.color.opacity(0.14))
                Image(systemName: "curlybraces.square.fill")
                    .font(.system(size: 27, weight: .semibold))
                    .foregroundStyle(palette.accent.color)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text("Json Lens")
                    .font(.title3.weight(.semibold))
                Text("Popup JSON browser")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private func refreshPermission() {
        accessibilityAllowed = SelectionReader.isTrusted()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            accessibilityAllowed = SelectionReader.isTrusted()
        }
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let palette: LensPalette
    private let content: Content

    init(title: String, palette: LensPalette, @ViewBuilder content: () -> Content) {
        self.title = title
        self.palette = palette
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(palette.pane.color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(palette.border.color)
            )
        }
    }
}

private struct ThemeTile: View {
    let theme: LensColorTheme
    let isSelected: Bool

    var body: some View {
        let palette = theme.palette

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(.system(size: 13, weight: .semibold))
                    Text(theme.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(palette.accent.color)
                }
            }

            HStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(palette.key.color)
                RoundedRectangle(cornerRadius: 3)
                    .fill(palette.string.color)
                RoundedRectangle(cornerRadius: 3)
                    .fill(palette.number.color)
                RoundedRectangle(cornerRadius: 3)
                    .fill(palette.bool.color)
                RoundedRectangle(cornerRadius: 3)
                    .fill(palette.null.color)
            }
            .frame(height: 14)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(palette.code.color)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? palette.accent.color : palette.border.color, lineWidth: isSelected ? 2 : 1)
        )
    }
}
