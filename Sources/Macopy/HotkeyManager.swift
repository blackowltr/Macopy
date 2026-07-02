import Cocoa
import Carbon

final class HotkeyManager {

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let callback: () -> Void

    private let hotKeyID = EventHotKeyID(signature: OSType(UInt32("MCYP".fourCharCode)), id: 1)

    init(callback: @escaping () -> Void) {
        self.callback = callback
    }

    func register() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetApplicationEventTarget(), { (_, eventRef, userData) -> OSStatus in
            guard let userData = userData else { return noErr }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.callback()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)

        let modifiers: UInt32 = UInt32(cmdKey)
        RegisterEventHotKey(11, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
    }

    deinit {
        unregister()
    }
}

private extension String {
    var fourCharCode: UInt32 {
        var result: UInt32 = 0
        for char in self.utf16 {
            result = (result << 8) + UInt32(char)
        }
        return result
    }
}
