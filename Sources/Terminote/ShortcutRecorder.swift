import AppKit
import SwiftUI

struct ShortcutRecorder: View {
    @ObservedObject var hotKeyManager: HotKeyManager
    @State private var isRecording = false
    @State private var registrationFailed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keyboard shortcut")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.primaryText)

            Button {
                registrationFailed = false
                isRecording = true
            } label: {
                Text(isRecording ? "Press a shortcut…" : hotKeyManager.shortcut.displayName)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(isRecording ? Theme.mutedText : Theme.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Theme.panelBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isRecording ? Theme.accent : Theme.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            if registrationFailed {
                Text("That shortcut is already in use.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.destructive)
            }

            KeyCaptureView(isRecording: $isRecording) { shortcut in
                registrationFailed = !hotKeyManager.rebind(to: shortcut)
            }
            .frame(width: 1, height: 1)
        }
        .padding(14)
        .frame(width: 230)
        .background(Theme.elevatedBackground)
        .preferredColorScheme(.dark)
    }
}

private struct KeyCaptureView: NSViewRepresentable {
    @Binding var isRecording: Bool
    let onShortcut: (HotKeyShortcut) -> Void

    func makeNSView(context: Context) -> CaptureView {
        let view = CaptureView()
        view.onShortcut = onShortcut
        view.onCancel = { isRecording = false }
        return view
    }

    func updateNSView(_ view: CaptureView, context: Context) {
        view.onShortcut = { shortcut in
            onShortcut(shortcut)
            isRecording = false
        }
        view.onCancel = { isRecording = false }
        if isRecording {
            DispatchQueue.main.async { view.window?.makeFirstResponder(view) }
        }
    }
}

private final class CaptureView: NSView {
    var onShortcut: ((HotKeyShortcut) -> Void)?
    var onCancel: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel?()
            return
        }
        let shortcut = HotKeyShortcut(event: event)
        guard shortcut.modifiers != 0 else {
            NSSound.beep()
            return
        }
        onShortcut?(shortcut)
    }
}
