import Foundation
import XCTest
@testable import Terminote

final class SettingsStoreTests: XCTestCase {
    @MainActor
    func testHistoryChangesOnlyForExplicitlySavedThemeChanges() {
        let suiteName = "TerminoteTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = SettingsStore(defaults: defaults)

        store.saveTheme(.default)
        XCTAssertTrue(store.savedThemes.isEmpty)

        let first = ThemeConfiguration(
            backgroundRGB: 0x112233,
            outlineRGB: 0xABCDEF,
            opacity: 0.72,
            usesLiquidGlass: false
        )
        store.saveTheme(first)
        XCTAssertEqual(store.theme, first)
        XCTAssertEqual(store.savedThemes.map(\.configuration), [first])

        store.saveTheme(first)
        XCTAssertEqual(store.savedThemes.count, 1)

        let second = ThemeConfiguration(
            backgroundRGB: 0xF0F0F0,
            outlineRGB: 0x303030,
            opacity: 0.85,
            usesLiquidGlass: true
        )
        store.saveTheme(second)
        XCTAssertEqual(store.savedThemes.map(\.configuration), [second, first])

        store.saveTheme(first)
        XCTAssertEqual(store.savedThemes.map(\.configuration), [first, second])

        let reloadedStore = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloadedStore.theme, first)
        XCTAssertEqual(reloadedStore.savedThemes.map(\.configuration), [first, second])
    }
}
