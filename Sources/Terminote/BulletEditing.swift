import Foundation

enum BulletEditing {
    static let marker = "• "

    struct Edit: Equatable {
        let range: NSRange
        let replacement: String
    }

    static func autoformatDash(in text: String, selection: NSRange) -> Edit? {
        guard selection.length == 0 else { return nil }
        let contents = text as NSString
        guard selection.location <= contents.length else { return nil }

        let lineStart = contents.lineRange(for: NSRange(location: selection.location, length: 0)).location
        let prefixRange = NSRange(location: lineStart, length: selection.location - lineStart)
        let prefix = contents.substring(with: prefixRange) as NSString
        let indentationLength = leadingWhitespaceLength(in: prefix)
        guard prefix.length == indentationLength + 1,
              prefix.character(at: indentationLength) == 45 else { return nil }

        return Edit(
            range: NSRange(location: lineStart + indentationLength, length: 1),
            replacement: marker
        )
    }

    static func continueList(in text: String, selection: NSRange) -> Edit? {
        guard selection.length == 0,
              let context = bulletContext(in: text, caret: selection.location) else { return nil }

        if context.body.trimmingCharacters(in: .whitespaces).isEmpty {
            return Edit(range: context.markerRange, replacement: "")
        }

        return Edit(
            range: selection,
            replacement: "\n\(context.indentation)\(marker)"
        )
    }

    static func removeMarkerOnBackspace(in text: String, selection: NSRange) -> Edit? {
        guard selection.length == 0,
              let context = bulletContext(in: text, caret: selection.location),
              selection.location == NSMaxRange(context.markerRange) else { return nil }
        return Edit(range: context.markerRange, replacement: "")
    }

    private struct BulletContext {
        let indentation: String
        let markerRange: NSRange
        let body: String
    }

    private static func bulletContext(in text: String, caret: Int) -> BulletContext? {
        let contents = text as NSString
        guard caret <= contents.length else { return nil }

        let lineRange = contents.lineRange(for: NSRange(location: caret, length: 0))
        let line = contents.substring(with: lineRange) as NSString
        let indentationLength = leadingWhitespaceLength(in: line)
        let markerRangeInLine = NSRange(location: indentationLength, length: (marker as NSString).length)
        guard NSMaxRange(markerRangeInLine) <= line.length,
              line.substring(with: markerRangeInLine) == marker else { return nil }

        var contentLength = line.length
        while contentLength > 0 {
            let character = line.character(at: contentLength - 1)
            guard character == 10 || character == 13 else { break }
            contentLength -= 1
        }

        let bodyStart = NSMaxRange(markerRangeInLine)
        let bodyLength = max(0, contentLength - bodyStart)
        return BulletContext(
            indentation: line.substring(with: NSRange(location: 0, length: indentationLength)),
            markerRange: NSRange(
                location: lineRange.location + markerRangeInLine.location,
                length: markerRangeInLine.length
            ),
            body: line.substring(with: NSRange(location: bodyStart, length: bodyLength))
        )
    }

    private static func leadingWhitespaceLength(in string: NSString) -> Int {
        var length = 0
        while length < string.length {
            let character = string.character(at: length)
            guard character == 32 || character == 9 else { break }
            length += 1
        }
        return length
    }
}
