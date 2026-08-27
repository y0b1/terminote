import AppKit
import SwiftUI

struct EditorView: NSViewRepresentable {
    @Binding var text: String
    let initialSelection: NSRange
    let showsLineNumbers: Bool
    let theme: ThemeConfiguration
    let onSelectionChange: (NSRange) -> Void
    let onClose: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = !Theme.usesLiquidGlass(theme)
        scrollView.backgroundColor = Theme.usesLiquidGlass(theme)
            ? .clear
            : NSColor(theme: Theme.editorBackground(theme))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.focusRingType = .none

        let textView = TerminoteTextView()
        textView.delegate = context.coordinator
        textView.onClose = onClose
        textView.theme = theme
        textView.focusRingType = .none
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainerInset = NSSize(
            width: showsLineNumbers ? 4 : 14,
            height: 12
        )
        textView.textContainer?.lineFragmentPadding = 0
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.usesFindPanel = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.string = text
        textView.applyEditorAttributes()
        textView.setSelectedRange(initialSelection)
        scrollView.documentView = textView
        scrollView.verticalRulerView = LineNumberRulerView(
            textView: textView,
            scrollView: scrollView,
            theme: theme,
            showsLineNumbers: showsLineNumbers
        )
        scrollView.hasVerticalRuler = showsLineNumbers
        scrollView.rulersVisible = showsLineNumbers

        context.coordinator.textView = textView
        DispatchQueue.main.async {
            if let window = textView.window {
                window.makeFirstResponder(textView)
                textView.scrollRangeToVisible(textView.selectedRange())
            }
        }
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? TerminoteTextView else { return }
        context.coordinator.parent = self
        textView.onClose = onClose
        textView.theme = theme
        textView.textContainerInset = NSSize(
            width: showsLineNumbers ? 4 : 14,
            height: 12
        )
        scrollView.drawsBackground = !Theme.usesLiquidGlass(theme)
        scrollView.backgroundColor = Theme.usesLiquidGlass(theme)
            ? .clear
            : NSColor(theme: Theme.editorBackground(theme))
        scrollView.hasVerticalRuler = showsLineNumbers
        scrollView.rulersVisible = showsLineNumbers
        if let ruler = scrollView.verticalRulerView as? LineNumberRulerView {
            ruler.theme = theme
            ruler.showsLineNumbers = showsLineNumbers
        }
        scrollView.verticalRulerView?.needsDisplay = true
        if textView.string != text {
            let oldSelection = textView.selectedRange()
            textView.string = text
            textView.applyEditorAttributes()
            let location = min(oldSelection.location, text.utf16.count)
            textView.setSelectedRange(NSRange(location: location, length: 0))
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: EditorView
        weak var textView: TerminoteTextView?

        init(_ parent: EditorView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView else { return }
            parent.text = textView.string
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView else { return }
            parent.onSelectionChange(textView.selectedRange())
            textView.needsDisplay = true
        }
    }
}

final class TerminoteTextView: NSTextView {
    var onClose: (() -> Void)?
    var theme: ThemeConfiguration = .default {
        didSet {
            guard theme != oldValue else { return }
            applyEditorAttributes()
            needsDisplay = true
        }
    }

    override func keyDown(with event: NSEvent) {
        if handleUndoShortcut(event) {
            return
        }

        if event.keyCode == 53 {
            onClose?()
            return
        }

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if modifiers.isEmpty,
           event.keyCode == 49,
           let edit = BulletEditing.autoformatDash(in: string, selection: selectedRange()) {
            perform(edit)
            return
        }
        if modifiers.isEmpty,
           (event.keyCode == 36 || event.keyCode == 76),
           let edit = BulletEditing.continueList(in: string, selection: selectedRange()) {
            perform(edit)
            return
        }
        if modifiers.isEmpty,
           event.keyCode == 51,
           let edit = BulletEditing.removeMarkerOnBackspace(in: string, selection: selectedRange()) {
            perform(edit)
            return
        }
        if event.keyCode == 48 && modifiers.isEmpty {
            insertText("  ", replacementRange: selectedRange())
            return
        }
        super.keyDown(with: event)
    }

    override func drawBackground(in rect: NSRect) {
        if !Theme.usesLiquidGlass(theme) {
            NSColor(theme: Theme.editorBackground(theme)).setFill()
            rect.fill()
        }
        super.drawBackground(in: rect)
    }

    func applyEditorAttributes() {
        let font = Theme.editorFont()
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = font.pointSize * 1.5
        paragraph.maximumLineHeight = font.pointSize * 1.5
        paragraph.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(theme: Theme.primaryText(theme)),
            .paragraphStyle: paragraph
        ]
        typingAttributes = attributes
        defaultParagraphStyle = paragraph
        textColor = NSColor(theme: Theme.primaryText(theme))
        insertionPointColor = NSColor(theme: Theme.caret(theme))
        selectedTextAttributes = [
            .backgroundColor: NSColor(theme: Theme.selectionBackground(theme)),
            .foregroundColor: NSColor(theme: Theme.primaryText(theme))
        ]
        drawsBackground = false
        textStorage?.setAttributes(attributes, range: NSRange(location: 0, length: textStorage?.length ?? 0))
    }

    private func perform(_ edit: BulletEditing.Edit) {
        breakUndoCoalescing()
        insertText(edit.replacement, replacementRange: edit.range)
        breakUndoCoalescing()
    }

    private func handleUndoShortcut(_ event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard event.charactersIgnoringModifiers?.lowercased() == "z",
              modifiers.contains(.command) || modifiers.contains(.control) else { return false }

        if modifiers.contains(.shift) {
            undoManager?.redo()
        } else {
            undoManager?.undo()
        }
        return true
    }
}
