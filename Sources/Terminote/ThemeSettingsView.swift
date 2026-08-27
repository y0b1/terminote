import SwiftUI

struct ThemeSettingsView: View {
    @ObservedObject var settings: SettingsStore
    let onDismiss: () -> Void

    @State private var backgroundColor: Color
    @State private var outlineColor: Color
    @State private var opacity: Double
    @State private var usesLiquidGlass: Bool

    init(settings: SettingsStore, onDismiss: @escaping () -> Void) {
        self.settings = settings
        self.onDismiss = onDismiss
        _backgroundColor = State(initialValue: settings.theme.backgroundColor)
        _outlineColor = State(initialValue: settings.theme.outlineColor)
        _opacity = State(initialValue: settings.theme.opacity)
        _usesLiquidGlass = State(initialValue: settings.theme.usesLiquidGlass)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Theme")
                .font(.system(size: 15, weight: .semibold))

            VStack(spacing: 12) {
                colorRow("Background", selection: $backgroundColor)
                colorRow("Outline", selection: $outlineColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Background opacity")
                    Spacer()
                    Text("\(Int((opacity * 100).rounded()))%")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(value: $opacity, in: 0.25...1, step: 0.01)
                    .tint(outlineColor)
            }

            liquidGlassSetting

            if !settings.savedThemes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Saved themes")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(settings.savedThemes) { savedTheme in
                                savedThemeButton(savedTheme)
                            }
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                Button("Reset") {
                    apply(.default)
                }
                .buttonStyle(.borderless)

                Spacer()

                Button("Cancel", action: onDismiss)
                    .keyboardShortcut(.cancelAction)

                Button("Save") {
                    settings.saveTheme(draft)
                    onDismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 320)
        .background(Theme.elevatedBackground(settings.theme))
        .foregroundStyle(Theme.primaryText(settings.theme))
        .preferredColorScheme(Theme.preferredColorScheme(settings.theme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.border(settings.theme), lineWidth: 1)
        }
    }

    private func colorRow(_ title: String, selection: Binding<Color>) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)

            ColorPicker(selection: selection, supportsOpacity: false) {
                EmptyView()
            }
            .labelsHidden()
            .frame(width: 40, height: 32, alignment: .trailing)
            .accessibilityLabel(title)
        }
        .frame(minHeight: 32)
    }

    @ViewBuilder
    private var liquidGlassSetting: some View {
        if #available(macOS 26.0, *) {
            Toggle("Liquid Glass", isOn: $usesLiquidGlass)
                .toggleStyle(.switch)
        } else {
            HStack {
                Text("Liquid Glass")
                Spacer()
                Text("Requires macOS 26")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var draft: ThemeConfiguration {
        ThemeConfiguration(
            backgroundRGB: backgroundColor.rgbValue,
            outlineRGB: outlineColor.rgbValue,
            opacity: opacity,
            usesLiquidGlass: usesLiquidGlass
        )
    }

    private func savedThemeButton(_ savedTheme: SavedTheme) -> some View {
        Button {
            apply(savedTheme.configuration)
        } label: {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(savedTheme.configuration.backgroundColor.opacity(savedTheme.configuration.opacity))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(savedTheme.configuration.outlineColor, lineWidth: 2)
                    }

                if savedTheme.configuration.usesLiquidGlass {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(savedTheme.configuration.outlineColor)
                        .padding(5)
                }
            }
            .frame(width: 34, height: 34)
            .frame(width: 40, height: 40)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(savedTheme.savedAt.formatted(date: .abbreviated, time: .shortened))
        .accessibilityLabel("Theme saved \(savedTheme.savedAt.formatted(date: .abbreviated, time: .shortened))")
    }

    private func apply(_ configuration: ThemeConfiguration) {
        backgroundColor = configuration.backgroundColor
        outlineColor = configuration.outlineColor
        opacity = configuration.opacity
        usesLiquidGlass = configuration.usesLiquidGlass
    }
}
