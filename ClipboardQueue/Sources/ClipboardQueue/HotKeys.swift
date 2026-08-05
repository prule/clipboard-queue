import AppKit
import Carbon.HIToolbox

/// System-wide ⌃⌥→ / ⌃⌥← / ⌃⌥C via the Carbon hot-key API — the only
/// registration path that doesn't require Accessibility permission.
final class HotKeyCenter {
    static let shared = HotKeyCenter()

    private var handlers: [UInt32: () -> Void] = [:]
    private var refs: [EventHotKeyRef?] = []
    private var installed = false
    private let signature: OSType = 0x43_4C_51_4B  // 'CLQK'

    private init() {}

    func register(id: UInt32, keyCode: Int, modifiers: UInt32, action: @escaping () -> Void) {
        installHandlerIfNeeded()
        handlers[id] = action

        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: signature, id: id)
        let status = RegisterEventHotKey(UInt32(keyCode), modifiers, hotKeyID,
                                         GetApplicationEventTarget(), 0, &ref)
        if status == noErr {
            refs.append(ref)
        } else {
            NSLog("ClipboardQueue: failed to register hot key \(id) (status \(status))")
        }
    }

    private func installHandlerIfNeeded() {
        guard !installed else { return }
        installed = true

        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ -> OSStatus in
            var hkID = EventHotKeyID()
            let err = GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                        EventParamType(typeEventHotKeyID), nil,
                                        MemoryLayout<EventHotKeyID>.size, nil, &hkID)
            guard err == noErr else { return err }
            DispatchQueue.main.async { HotKeyCenter.shared.handlers[hkID.id]?() }
            return noErr
        }, 1, &spec, nil, nil)
    }
}

enum HotKey {
    static let skip: UInt32 = 1
    static let back: UInt32 = 2
    static let openWindow: UInt32 = 3

    static let controlOption = UInt32(controlKey | optionKey)
}
