import AppKit
import SwiftUI

struct EditorView: NSViewRepresentable {
    @Binding var text: String
    let initialSelection: NSRange
    let showsLineNumbers: Bool
    let onSelectionChange: (NSRange) -> Void
    let onClose: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor(theme: Theme.editorBackground)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.focusRingType = .none

        let textView = TerminoteTextView()
        textView.delegate = context.coordinator
        textView.onClose = onClose
        textView.focusRingType = .none
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainerInset = NSSize(width: 14, height: 12)
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
        scrollView.verticalRulerView = LineNumberRulerView(textView: textView, scrollView: scrollView)
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
        textView.onClose = onClose
        scrollView.hasVerticalRuler = showsLineNumbers
        scrollView.rulersVisible = showsLineNumbers
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

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onClose?()
            return
        }
        if event.keyCode == 48 && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
            insertText("  ", replacementRange: selectedRange())
            return
        }
        super.keyDown(with: event)
    }

    override func drawBackground(in rect: NSRect) {
        NSColor(theme: Theme.editorBackground).setFill()
        rect.fill()
        drawCurrentLineHighlight(in: rect)
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
            .foregroundColor: NSColor(theme: Theme.primaryText),
            .paragraphStyle: paragraph
        ]
        typingAttributes = attributes
        defaultParagraphStyle = paragraph
        textColor = NSColor(theme: Theme.primaryText)
        insertionPointColor = NSColor(theme: Theme.caret)
        selectedTextAttributes = [
            .backgroundColor: NSColor(theme: Theme.selectionBackground),
            .foregroundColor: NSColor(theme: Theme.primaryText)
        ]
        drawsBackground = false
        textStorage?.setAttributes(attributes, range: NSRange(location: 0, length: textStorage?.length ?? 0))
    }

    private func drawCurrentLineHighlight(in dirtyRect: NSRect) {
        guard selectedRange().length == 0,
              let layoutManager,
              let textContainer else { return }

        let contents = string as NSString
        let lineRange = contents.lineRange(for: NSRange(location: min(selectedRange().location, contents.length), length: 0))
        var lineRect: NSRect
        if lineRange.location == contents.length, layoutManager.extraLineFragmentTextContainer === textContainer {
            lineRect = layoutManager.extraLineFragmentRect
        } else if layoutManager.numberOfGlyphs > 0 {
            let glyph = min(layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil).location,
                            layoutManager.numberOfGlyphs - 1)
            lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
        } else {
            lineRect = NSRect(x: 0, y: textContainerInset.height, width: bounds.width, height: Theme.editorFont().pointSize * 1.5)
        }

        lineRect.origin.x = 0
        lineRect.size.width = bounds.width
        guard lineRect.intersects(dirtyRect) else { return }
        NSColor(theme: Theme.currentLineHighlight).setFill()
        lineRect.fill()
    }
}
