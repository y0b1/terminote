import SwiftUI

struct PanelView: View {
    @ObservedObject var workspace: WorkspaceStore
    @ObservedObject var settings: SettingsStore

    var body: some View {
        NotePaneView(note: workspace.note, settings: settings)
            .frame(
                minWidth: 420,
                idealWidth: 420,
                maxWidth: 420,
                minHeight: 260,
                idealHeight: PanelController.shared.savedHeight,
                maxHeight: 900
            )
            .background(PanelSurface(theme: settings.theme))
            .background(WindowReader(theme: settings.theme).frame(width: 0, height: 0))
            .preferredColorScheme(Theme.preferredColorScheme(settings.theme))
    }
}

private struct NotePaneView: View {
    @ObservedObject var note: NoteStore
    @ObservedObject var settings: SettingsStore

    var body: some View {
        EditorView(
            text: $note.text,
            initialSelection: note.selection,
            showsLineNumbers: settings.showsLineNumbers,
            theme: settings.theme,
            onSelectionChange: note.setSelection,
            onClose: PanelController.shared.close
        )
    }
}

private struct PanelSurface: View {
    let theme: ThemeConfiguration

    @ViewBuilder
    var body: some View {
        if #available(macOS 26.0, *), theme.usesLiquidGlass {
            Color.clear
                .glassEffect(
                    .regular.tint(theme.backgroundColor),
                    in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                )
                .opacity(theme.opacity)
        } else {
            Theme.panelBackground(theme)
        }
    }
}
