import AppKit
import Carbon
import Combine
import Foundation

struct HotKeyShortcut: Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let `default` = HotKeyShortcut(
        keyCode: UInt32(kVK_Space),
        modifiers: UInt32(controlKey | optionKey)
    )

    var displayName: String {
        var result = ""
        if modifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { result += "⌘" }
        result += Self.keyName(for: keyCode)
        return result
    }

    init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    init(event: NSEvent) {
        keyCode = UInt32(event.keyCode)
        var carbonModifiers: UInt32 = 0
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags.contains(.control) { carbonModifiers |= UInt32(controlKey) }
        if flags.contains(.option) { carbonModifiers |= UInt32(optionKey) }
        if flags.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
        if flags.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
        modifiers = carbonModifiers
    }

    private static func keyName(for code: UInt32) -> String {
        let names: [UInt32: String] = [
            UInt32(kVK_Space): "Space", UInt32(kVK_Return): "↩",
            UInt32(kVK_Tab): "⇥", UInt32(kVK_Delete): "⌫",
            UInt32(kVK_LeftArrow): "←", UInt32(kVK_RightArrow): "→",
            UInt32(kVK_UpArrow): "↑", UInt32(kVK_DownArrow): "↓",
            UInt32(kVK_ANSI_A): "A", UInt32(kVK_ANSI_B): "B",
            UInt32(kVK_ANSI_C): "C", UInt32(kVK_ANSI_D): "D",
            UInt32(kVK_ANSI_E): "E", UInt32(kVK_ANSI_F): "F",
            UInt32(kVK_ANSI_G): "G", UInt32(kVK_ANSI_H): "H",
            UInt32(kVK_ANSI_I): "I", UInt32(kVK_ANSI_J): "J",
            UInt32(kVK_ANSI_K): "K", UInt32(kVK_ANSI_L): "L",
            UInt32(kVK_ANSI_M): "M", UInt32(kVK_ANSI_N): "N",
            UInt32(kVK_ANSI_O): "O", UInt32(kVK_ANSI_P): "P",
            UInt32(kVK_ANSI_Q): "Q", UInt32(kVK_ANSI_R): "R",
            UInt32(kVK_ANSI_S): "S", UInt32(kVK_ANSI_T): "T",
            UInt32(kVK_ANSI_U): "U", UInt32(kVK_ANSI_V): "V",
            UInt32(kVK_ANSI_W): "W", UInt32(kVK_ANSI_X): "X",
            UInt32(kVK_ANSI_Y): "Y", UInt32(kVK_ANSI_Z): "Z",
            UInt32(kVK_ANSI_0): "0", UInt32(kVK_ANSI_1): "1",
            UInt32(kVK_ANSI_2): "2", UInt32(kVK_ANSI_3): "3",
            UInt32(kVK_ANSI_4): "4", UInt32(kVK_ANSI_5): "5",
            UInt32(kVK_ANSI_6): "6", UInt32(kVK_ANSI_7): "7",
            UInt32(kVK_ANSI_8): "8", UInt32(kVK_ANSI_9): "9"
        ]
        return names[code] ?? "Key \(code)"
    }
}

@MainActor
final class HotKeyManager: ObservableObject {
    @Published private(set) var shortcut: HotKeyShortcut

    var onPressed: (() -> Void)?

    private let defaults = UserDefaults.standard
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    init() {
        if defaults.object(forKey: "hotKeyCode") != nil {
            shortcut = HotKeyShortcut(
                keyCode: UInt32(defaults.integer(forKey: "hotKeyCode")),
                modifiers: UInt32(defaults.integer(forKey: "hotKeyModifiers"))
            )
        } else {
            shortcut = .default
        }
        installHandler()
        _ = register(shortcut)
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }

    @discardableResult
    func rebind(to candidate: HotKeyShortcut) -> Bool {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        hotKeyRef = nil

        guard register(candidate) == noErr else {
            _ = register(shortcut)
            return false
        }

        shortcut = candidate
        defaults.set(Int(candidate.keyCode), forKey: "hotKeyCode")
        defaults.set(Int(candidate.modifiers), forKey: "hotKeyModifiers")
        return true
    }

    private func installHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // Carbon hotkeys are system-wide without an Accessibility permission prompt.
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return noErr }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async { manager.onPressed?() }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )
    }

    private func register(_ shortcut: HotKeyShortcut) -> OSStatus {
        let identifier = EventHotKeyID(signature: OSType(0x54524D4E), id: 1) // TRMN
        return RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            identifier,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
}
