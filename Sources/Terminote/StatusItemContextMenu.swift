@preconcurrency import AppKit
import SwiftUI

@MainActor
final class StatusItemContextMenu: NSObject {
    private let model: AppModel
    private var eventMonitor: Any?
    private var shortcutPopover: NSPopover?
    private var themePanel: NSPanel?
    private weak var contextButton: NSButton?

    init(model: AppModel) {
        self.model = model
    }

    func start() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.rightMouseDown, .leftMouseDown]
        ) { [weak self] event in
            guard let self else { return event }
            let isContextClick = event.type == .rightMouseDown
                || (event.type == .leftMouseDown && event.modifierFlags.contains(.control))
            guard isContextClick else { return event }

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
        themePanel?.close()
    }

    private func showMenu(from button: NSButton) {
        contextButton = button
        model.launchAtLogin.refresh()

        let menu = NSMenu()
        let lineNumbersItem = item("Show line numbers", action: #selector(toggleLineNumbers))
        lineNumbersItem.state = model.settings.showsLineNumbers ? .on : .off
        menu.addItem(lineNumbersItem)
        menu.addItem(item("Theme…", action: #selector(changeTheme)))
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
            rootView: ShortcutRecorder(
                hotKeyManager: model.hotKeyManager,
                theme: model.settings.theme
            )
        )
        shortcutPopover = popover
        DispatchQueue.main.async {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    @objc private func changeTheme() {
        guard let button = contextButton ?? PanelController.shared.statusItemButton() else { return }
        themePanel?.close()

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 340),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "Theme"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.hasShadow = true
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.contentViewController = NSHostingController(
            rootView: ThemeSettingsView(settings: model.settings) { [weak self, weak panel] in
                panel?.close()
                if self?.themePanel === panel {
                    self?.themePanel = nil
                }
            }
        )

        let fittingSize = panel.contentViewController?.view.fittingSize
            ?? NSSize(width: 320, height: 340)
        panel.setContentSize(NSSize(width: 320, height: max(300, fittingSize.height)))
        positionThemePanel(panel, beside: PanelController.shared.window, fallbackButton: button)
        themePanel = panel
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
    }

    private func positionThemePanel(_ panel: NSPanel, beside noteWindow: NSWindow?, fallbackButton: NSButton) {
        let gap: CGFloat = 12
        let screen = noteWindow?.screen ?? fallbackButton.window?.screen ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else { return }

        let panelSize = panel.frame.size
        if let noteFrame = noteWindow?.frame {
            let rightX = noteFrame.maxX + gap
            let leftX = noteFrame.minX - panelSize.width - gap
            let x = rightX + panelSize.width <= visibleFrame.maxX
                ? rightX
                : max(visibleFrame.minX, leftX)
            let y = min(
                max(noteFrame.maxY - panelSize.height, visibleFrame.minY),
                visibleFrame.maxY - panelSize.height
            )
            panel.setFrameOrigin(NSPoint(x: x, y: y))
            return
        }

        let buttonFrame = fallbackButton.window.map {
            $0.convertToScreen(fallbackButton.convert(fallbackButton.bounds, to: nil))
        } ?? .zero
        panel.setFrameOrigin(NSPoint(
            x: min(max(buttonFrame.midX + gap, visibleFrame.minX), visibleFrame.maxX - panelSize.width),
            y: visibleFrame.maxY - panelSize.height
        ))
    }

    @objc private func quit() {
        model.workspace.flush()
        NSApp.terminate(nil)
    }
}
