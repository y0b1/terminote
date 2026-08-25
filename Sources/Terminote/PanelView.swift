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
            .background(Theme.editorBackground)
            .background(WindowReader().frame(width: 0, height: 0))
            .preferredColorScheme(.dark)
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
            onSelectionChange: note.setSelection,
            onClose: PanelController.shared.close
        )
    }
}
