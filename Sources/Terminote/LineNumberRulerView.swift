import AppKit

final class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?
    private var observers: [NSObjectProtocol] = []

    init(textView: NSTextView, scrollView: NSScrollView) {
        self.textView = textView
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        clientView = textView
        ruleThickness = 40

        scrollView.contentView.postsBoundsChangedNotifications = true
        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: NSText.didChangeNotification,
            object: textView,
            queue: .main
        ) { [weak self] _ in self?.needsDisplay = true })
        observers.append(center.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { [weak self] _ in self?.needsDisplay = true })
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        NSColor(theme: Theme.editorBackground).setFill()
        rect.fill()

        let separator = NSRect(x: bounds.maxX - 1, y: rect.minY, width: 1, height: rect.height)
        NSColor(theme: Theme.border).setFill()
        separator.fill()

        let contents = textView.string as NSString
        let visibleRect = textView.visibleRect
        var characterIndex = 0
        var lineNumber = 1

        if contents.length == 0 {
            let emptyLine = NSRect(
                x: 0,
                y: textView.textContainerInset.height,
                width: 0,
                height: Theme.editorFont().pointSize * 1.5
            )
            draw(lineNumber: 1, for: emptyLine, in: textView)
            return
        }

        while characterIndex < contents.length {
            let lineRange = contents.lineRange(for: NSRange(
                location: characterIndex,
                length: 0
            ))
            let lineRect: NSRect

            if layoutManager.numberOfGlyphs > 0 {
                let glyphIndex = min(
                    layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil).location,
                    layoutManager.numberOfGlyphs - 1
                )
                lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
            } else {
                lineRect = NSRect(
                    x: 0,
                    y: textView.textContainerInset.height,
                    width: 0,
                    height: Theme.editorFont().pointSize * 1.5
                )
            }

            if lineRect.maxY >= visibleRect.minY && lineRect.minY <= visibleRect.maxY {
                draw(lineNumber: lineNumber, for: lineRect, in: textView)
            }

            let nextIndex = NSMaxRange(lineRange)
            guard nextIndex > characterIndex else { break }
            characterIndex = nextIndex
            lineNumber += 1
        }

        let finalCharacter = contents.character(at: contents.length - 1)
        if (finalCharacter == 10 || finalCharacter == 13),
           layoutManager.extraLineFragmentTextContainer === textContainer {
            draw(lineNumber: lineNumber, for: layoutManager.extraLineFragmentRect, in: textView)
        }
    }

    private func draw(lineNumber: Int, for lineRect: NSRect, in textView: NSTextView) {
        let value = "\(lineNumber)" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: Theme.editorFont(size: 11),
            .foregroundColor: NSColor(theme: Theme.mutedText)
        ]
        let size = value.size(withAttributes: attributes)
        let converted = convert(lineRect, from: textView)
        value.draw(
            at: NSPoint(
                x: ruleThickness - size.width - 8,
                y: converted.minY + (converted.height - size.height) / 2
            ),
            withAttributes: attributes
        )
    }
}
