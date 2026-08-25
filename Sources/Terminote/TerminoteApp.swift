import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    let workspace: WorkspaceStore
    let settings: SettingsStore
    let hotKeyManager: HotKeyManager
    let launchAtLogin: LaunchAtLoginController

    private init() {
        Self.migrateLegacyPreferencesIfNeeded()
        workspace = WorkspaceStore()
        settings = SettingsStore()
        hotKeyManager = HotKeyManager()
        launchAtLogin = LaunchAtLoginController()
    }

    private static func migrateLegacyPreferencesIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "didMigrateScratchPreferences"),
              let legacy = defaults.persistentDomain(forName: "com.scratchapp.Scratch") else { return }

        for key in [
            "hotKeyCode", "hotKeyModifiers", "panelHeight",
            "selectionLocation", "selectionLength"
        ] where defaults.object(forKey: key) == nil {
            defaults.set(legacy[key], forKey: key)
        }
        defaults.set(true, forKey: "didMigrateScratchPreferences")
    }
}

@main
struct TerminoteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let model = AppModel.shared

    var body: some Scene {
        MenuBarExtra {
            PanelView(workspace: model.workspace, settings: model.settings)
        } label: {
            Image(systemName: "square.and.pencil")
                .accessibilityLabel("Terminote")
        }
        .menuBarExtraStyle(.window)
    }
}
