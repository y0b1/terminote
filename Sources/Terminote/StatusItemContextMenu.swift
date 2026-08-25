@preconcurrency import AppKit
import SwiftUI

@MainActor
final class StatusItemContextMenu: NSObject {
    private let model: AppModel
    private var eventMonitor: Any?
    private var shortcutPopover: NSPopover?

    init(model: AppModel) {
        self.model = model
    }

    func start() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            guard let self else { return event }
            let windowNumber = event.windowNumber
            let location = event.locationInWindow
            let handled = MainActor.assumeIsolated {
                guard let button = PanelController.shared.statusItemButton(),
                      button.window?.windowNumber == windowNumber,
                      button.bounds.contains(button.convert(location, from: nil)) else {
                    return false
                }

                self.showMenu(from: button)
                return true
            }
            return handled ? nil : event
        }
    }

    func stop() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        eventMonitor = nil
        shortcutPopover?.close()
    }

    private func showMenu(from button: NSButton) {
        model.launchAtLogin.refresh()

        let menu = NSMenu()
        let lineNumbersItem = item("Show line numbers", action: #selector(toggleLineNumbers))
        lineNumbersItem.state = model.settings.showsLineNumbers ? .on : .off
        menu.addItem(lineNumbersItem)
        menu.addItem(.separator())
        menu.addItem(item("Open containing folder", action: #selector(openContainingFolder)))
        menu.addItem(.separator())

        let launchItem = item("Launch at login", action: #selector(toggleLaunchAtLogin))
        launchItem.state = model.launchAtLogin.isEnabled ? .on : .off
        menu.addItem(launchItem)
        menu.addItem(item("Change shortcut…", action: #selector(changeShortcut)))
        menu.addItem(.separator())
        menu.addItem(item("Quit", action: #selector(quit)))

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.minY), in: button)
    }

    private func item(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc private func openContainingFolder() {
        model.workspace.flush()
        NSWorkspace.shared.open(model.workspace.containingFolder)
    }

    @objc private func toggleLineNumbers() {
        model.settings.showsLineNumbers.toggle()
    }

    @objc private func toggleLaunchAtLogin() {
        model.launchAtLogin.setEnabled(!model.launchAtLogin.isEnabled)
    }

    @objc private func changeShortcut() {
        guard let button = PanelController.shared.statusItemButton() else { return }
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 230, height: 118)
        popover.contentViewController = NSHostingController(
            rootView: ShortcutRecorder(hotKeyManager: model.hotKeyManager)
        )
        shortcutPopover = popover
        DispatchQueue.main.async {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    @objc private func quit() {
        model.workspace.flush()
        NSApp.terminate(nil)
    }
}
