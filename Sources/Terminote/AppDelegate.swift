import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let singleInstance = SingleInstance()
    private var distributedObserver: NSObjectProtocol?
    private var sleepObserver: NSObjectProtocol?
    private var statusItemContextMenu: StatusItemContextMenu?

    func applicationWillFinishLaunching(_ notification: Notification) {
        guard singleInstance.acquire() else {
            DistributedNotificationCenter.default().postNotificationName(
                SingleInstance.activationNotification,
                object: nil,
                deliverImmediately: true
            )
            DispatchQueue.main.async { NSApp.terminate(nil) }
            return
        }

        distributedObserver = DistributedNotificationCenter.default().addObserver(
            forName: SingleInstance.activationNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in PanelController.shared.open() }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let model = AppModel.shared
        PanelController.shared.onClose = { model.workspace.flush() }
        model.hotKeyManager.onPressed = { PanelController.shared.toggle() }
        statusItemContextMenu = StatusItemContextMenu(model: model)
        statusItemContextMenu?.start()

        sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in AppModel.shared.workspace.flush() }
        }

        DispatchQueue.main.async {
            PanelController.shared.open()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppModel.shared.workspace.flush()
        statusItemContextMenu?.stop()
        if let distributedObserver {
            DistributedNotificationCenter.default().removeObserver(distributedObserver)
        }
        if let sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(sleepObserver)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
