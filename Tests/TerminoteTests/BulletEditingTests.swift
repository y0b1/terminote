import Foundation
import AppKit
import XCTest
@testable import Terminote

final class BulletEditingTests: XCTestCase {
    func testDashAtStartOfLineBecomesBullet() {
        let edit = BulletEditing.autoformatDash(
            in: "-",
            selection: NSRange(location: 1, length: 0)
        )

        XCTAssertEqual(edit, .init(range: NSRange(location: 0, length: 1), replacement: "• "))
    }

    func testIndentedDashKeepsIndentation() {
        let edit = BulletEditing.autoformatDash(
            in: "  -",
            selection: NSRange(location: 3, length: 0)
        )

        XCTAssertEqual(edit, .init(range: NSRange(location: 2, length: 1), replacement: "• "))
    }

    func testReturnContinuesNonEmptyBullet() {
        let edit = BulletEditing.continueList(
            in: "• idea",
            selection: NSRange(location: 6, length: 0)
        )

        XCTAssertEqual(edit, .init(range: NSRange(location: 6, length: 0), replacement: "\n• "))
    }

    func testReturnExitsEmptyBullet() {
        let edit = BulletEditing.continueList(
            in: "• ",
            selection: NSRange(location: 2, length: 0)
        )

        XCTAssertEqual(edit, .init(range: NSRange(location: 0, length: 2), replacement: ""))
    }

    func testBackspaceOnceRemovesEmptyMarker() {
        let edit = BulletEditing.removeMarkerOnBackspace(
            in: "• ",
            selection: NSRange(location: 2, length: 0)
        )

        XCTAssertEqual(edit, .init(range: NSRange(location: 0, length: 2), replacement: ""))
    }

    func testBackspaceInBulletBodyUsesNormalEditing() {
        let edit = BulletEditing.removeMarkerOnBackspace(
            in: "• idea",
            selection: NSRange(location: 6, length: 0)
        )

        XCTAssertNil(edit)
    }

    @MainActor
    func testBulletAutoformatIsOneControlZUndoStep() throws {
        let textView = TerminoteTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.contentView = textView
        window.makeFirstResponder(textView)
        textView.allowsUndo = true
        textView.string = "-"
        textView.setSelectedRange(NSRange(location: 1, length: 0))

        textView.keyDown(with: try keyEvent(characters: " ", keyCode: 49))
        XCTAssertEqual(textView.string, "• ")

        textView.keyDown(with: try keyEvent(characters: "z", modifiers: .control, keyCode: 6))
        XCTAssertEqual(textView.string, "-")

        textView.keyDown(with: try keyEvent(
            characters: "z",
            modifiers: [.control, .shift],
            keyCode: 6
        ))
        XCTAssertEqual(textView.string, "• ")
    }

    private func keyEvent(
        characters: String,
        modifiers: NSEvent.ModifierFlags = [],
        keyCode: UInt16
    ) throws -> NSEvent {
        try XCTUnwrap(NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: modifiers,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: characters,
            charactersIgnoringModifiers: characters,
            isARepeat: false,
            keyCode: keyCode
        ))
    }
}
