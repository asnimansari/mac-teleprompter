import Carbon

/// Global hotkeys via Carbon (no Accessibility permission needed).
@MainActor
final class HotKeys {
    nonisolated(unsafe) private static var handlers: [UInt32: () -> Void] = [:]
    private var refs: [EventHotKeyRef?] = []
    private var nextID: UInt32 = 1

    init() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hkID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &hkID)
            let id = hkID.id
            DispatchQueue.main.async { HotKeys.handlers[id]?() }
            return noErr
        }, 1, &spec, nil, nil)
    }

    /// Registers ⌃⌥ + keyCode.
    func register(keyCode: Int, action: @escaping () -> Void) {
        let id = nextID
        nextID += 1
        HotKeys.handlers[id] = action
        var ref: EventHotKeyRef?
        let hkID = EventHotKeyID(signature: OSType(0x4D43_5450), id: id) // "MCTP"
        RegisterEventHotKey(UInt32(keyCode), UInt32(controlKey | optionKey), hkID, GetApplicationEventTarget(), 0, &ref)
        refs.append(ref)
    }
}
