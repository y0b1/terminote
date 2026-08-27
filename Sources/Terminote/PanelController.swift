import AppKit
import SwiftUI

@MainActor
final class PanelController {
    static let shared = PanelController()

    weak var window: NSWindow?
    var onClose: (() -> Void)?

    private var windowObservers: [NSObjectProtocol] = []
    private let defaults = UserDefaults.standard
    private let defaultSize = NSSize(width: 420, height: 520)

    var savedHeight: CGFloat {
        let value = defaults.double(forKey: "panelHeight")
        return value > 0 ? value : defaultSize.height
    }

    func capture(window: NSWindow, theme: ThemeConfiguration) {
        if self.window !== window {
            removeObservers()
            self.window = window
            configure(window, theme: theme)
            observe(window)
        }
        applyTheme(theme, to: window)

        DispatchQueue.main.async {
            window.makeKey()
            if !(window.firstResponder is NSTextView),
               let editor = self.findTextView(in: window.contentView) {
                window.makeFirstResponder(editor)
            }
        }
    }

    func toggle() {
        if let window, window.isVisible {
            close()
        } else {
            open()
        }
    }

    func open() {
        if let window, window.isVisible {
            window.makeKey()
            return
        }
        clickStatusItem(retriesRemaining: 20)
    }

    func close() {
        onClose?()
        window?.orderOut(nil)
    }

    private func configure(_ window: NSWindow, theme: ThemeConfiguration) {
        window.styleMask.insert(.resizable)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = Theme.cornerRadius
        window.contentView?.layer?.cornerCurve = .continuous
        window.contentView?.layer?.masksToBounds = true
        window.contentView?.layer?.borderWidth = 1
        window.contentView?.layer?.borderColor = NSColor(theme: Theme.border(theme)).cgColor
        window.contentMinSize = NSSize(width: defaultSize.width, height: 260)
        window.contentMaxSize = NSSize(width: defaultSize.width, height: 900)
        window.setContentSize(NSSize(width: defaultSize.width, height: savedHeight))
    }

    private func applyTheme(_ theme: ThemeConfiguration, to window: NSWindow) {
        window.contentView?.layer?.borderColor = NSColor(theme: Theme.border(theme)).cgColor
    }

    private func observe(_ window: NSWindow) {
        let center = NotificationCenter.default
        windowObservers.append(center.addObserver(
            forName: NSWindow.didResizeNotification,
            object: window,
            queue: .main
        ) { [weak self, weak window] _ in
            Task { @MainActor in
                guard let self, let window else { return }
                self.defaults.set(window.contentLayoutRect.height, forKey: "panelHeight")
            }
        })
        windowObservers.append(center.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.onClose?() }
        })
    }

    private func removeObservers() {
        for observer in windowObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        windowObservers.removeAll()
    }

    private func clickStatusItem(retriesRemaining: Int) {
        if let button = statusItemButton() {
            button.performClick(nil)
            return
        }
        guard retriesRemaining > 0 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(8)) { [weak self] in
            self?.clickStatusItem(retriesRemaining: retriesRemaining - 1)
        }
    }

    func statusItemButton() -> NSButton? {
        for window in NSApp.windows
        where window.frame.height <= 40
            && (window.level == .statusBar || String(describing: type(of: window)).contains("StatusBar")) {
            if let button = findButton(in: window.contentView) {
                return button
            }
        }
        return nil
    }

    private func findButton(in view: NSView?) -> NSButton? {
        guard let view else { return nil }
        if let button = view as? NSButton { return button }
        for subview in view.subviews {
            if let button = findButton(in: subview) { return button }
        }
        return nil
    }

    private func findTextView(in view: NSView?) -> NSTextView? {
        guard let view else { return nil }
        if let textView = view as? NSTextView { return textView }
        for subview in view.subviews {
            if let textView = findTextView(in: subview) { return textView }
        }
        return nil
    }
}

struct WindowReader: NSViewRepresentable {
    let theme: ThemeConfiguration

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [weak view, theme] in
            if let window = view?.window {
                PanelController.shared.capture(window: window, theme: theme)
            }
        }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async { [weak view, theme] in
            if let window = view?.window {
                PanelController.shared.capture(window: window, theme: theme)
            }
        }
    }
}
