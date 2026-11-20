import AppKit

/// Borderless, non-activating panel pinned above the menu bar at the notch.
final class PrompterPanel: NSPanel {
    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isFloatingPanel = true
        level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 3)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        hidesOnDeactivate = false
        sharingType = .none // hide from screen recording / sharing
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// Built-in display (with the notch / camera) if present, else main.
    static func targetScreen() -> NSScreen? {
        if let notched = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) { return notched }
        let builtIn = NSScreen.screens.first { screen in
            guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else { return false }
            return CGDisplayIsBuiltin(id) != 0
        }
        return builtIn ?? NSScreen.main
    }
}

/// Swallows all mouse events so the SwiftUI content stays passive.
final class PrompterHostView: NSView {
    var onClick: (() -> Void)?
    var onScroll: ((NSEvent) -> Void)?

    override func hitTest(_ point: NSPoint) -> NSView? { frame.contains(point) ? self : nil }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) {}
    override func mouseUp(with event: NSEvent) { onClick?() }
    override func scrollWheel(with event: NSEvent) { onScroll?(event) }
}
