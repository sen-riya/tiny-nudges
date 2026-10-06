import Carbon.HIToolbox

/// Global Esc shortcut, active only while the character is on screen.
/// (Registered as a system hot key, so it works without any Accessibility permission.)
@MainActor
final class EscapeHotKey {
    private static var action: (() -> Void)?
    private static var handler: EventHandlerRef?
    private var ref: EventHotKeyRef?

    func register(_ action: @escaping () -> Void) {
        unregister()
        Self.action = action
        if Self.handler == nil {
            var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
                DispatchQueue.main.async { EscapeHotKey.action?() }
                return noErr
            }, 1, &spec, nil, &Self.handler)
        }
        let id = EventHotKeyID(signature: OSType(0x5245_4D44), id: 1)
        RegisterEventHotKey(UInt32(kVK_Escape), 0, id, GetApplicationEventTarget(), 0, &ref)
    }

    func unregister() {
        if let ref { UnregisterEventHotKey(ref) }
        ref = nil
        Self.action = nil
    }
}
