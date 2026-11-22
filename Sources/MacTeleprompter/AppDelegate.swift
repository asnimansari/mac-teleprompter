import AppKit
import Carbon
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let settings = Settings.shared
    private lazy var controller = PrompterController(settings: settings)
    private let panel = PrompterPanel()
    private let host = PrompterHostView()
    private var hosting: NSHostingView<PrompterView>?
    private var statusItem: NSStatusItem!
    private var hotKeys: HotKeys?
    private let editor = EditorWindowController()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMainMenu()
        setupStatusItem()
        setupPanel()
        setupHotKeys()

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in MainActor.assumeIsolated { self?.layoutPanel() } }

        settings.$size.dropFirst()
            .sink { [weak self] size in self?.layoutPanel(size: size) }
            .store(in: &cancellables)

        if settings.script.isEmpty { editor.show(settings: settings) }
    }

    // MARK: Panel

    private func setupPanel() {
        host.onClick = { [weak self] in self?.controller.toggle() }
        host.onScroll = { [weak self] in self?.controller.manualScroll($0) }
        panel.contentView = host
        layoutPanel()
        panel.orderFrontRegardless()
    }

    private func layoutPanel(size: PanelSize? = nil) {
        guard let screen = PrompterPanel.targetScreen() else { return }
        let s = size ?? settings.size
        let notch = screen.safeAreaInsets.top
        let hasNotch = notch > 0
        let w = s.size.width
        let h = notch + s.size.height
        let topY = hasNotch ? screen.frame.maxY : screen.visibleFrame.maxY
        panel.setFrame(NSRect(x: screen.frame.midX - w / 2, y: topY - h, width: w, height: h), display: true)

        let view = PrompterView(settings: settings, controller: controller, size: s, topInset: notch, hasNotch: hasNotch)
        if let hosting {
            hosting.rootView = view
        } else {
            let hv = NSHostingView(rootView: view)
            hv.frame = host.bounds
            hv.autoresizingMask = [.width, .height]
            host.addSubview(hv)
            hosting = hv
        }
    }

    private func togglePanel() {
        if panel.isVisible {
            controller.pause()
            panel.orderOut(nil)
        } else {
            layoutPanel()
            panel.orderFrontRegardless()
        }
    }

    // MARK: Hotkeys

    private func setupHotKeys() {
        let hk = HotKeys()
        hk.register(keyCode: kVK_Space) { [weak self] in self?.controller.toggle() }
        hk.register(keyCode: kVK_UpArrow) { [weak self] in self?.controller.changeSpeed(by: 10) }
        hk.register(keyCode: kVK_DownArrow) { [weak self] in self?.controller.changeSpeed(by: -10) }
        hk.register(keyCode: kVK_ANSI_R) { [weak self] in self?.controller.restart() }
        hk.register(keyCode: kVK_ANSI_H) { [weak self] in self?.togglePanel() }
        hotKeys = hk
    }

    // MARK: Menus

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "text.alignleft", accessibilityDescription: "Mac Teleprompter")
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        menu.addItem(ActionItem(controller.isBusy ? "Pause" : "Play", key: "⌃⌥Space") { [weak self] in self?.controller.toggle() })
        menu.addItem(ActionItem("Restart", key: "⌃⌥R") { [weak self] in self?.controller.restart() })
        menu.addItem(ActionItem(panel.isVisible ? "Hide Prompter" : "Show Prompter", key: "⌃⌥H") { [weak self] in self?.togglePanel() })
        menu.addItem(.separator())

        let speed = NSMenuItem(title: "Speed: \(settings.wpm) wpm", action: nil, keyEquivalent: "")
        speed.isEnabled = false
        menu.addItem(speed)
        menu.addItem(ActionItem("Faster", key: "⌃⌥↑") { [weak self] in self?.controller.changeSpeed(by: 10) })
        menu.addItem(ActionItem("Slower", key: "⌃⌥↓") { [weak self] in self?.controller.changeSpeed(by: -10) })
        menu.addItem(.separator())

        let sizeMenu = NSMenu()
        for size in PanelSize.allCases {
            let item = ActionItem(size.label) { [weak self] in self?.settings.size = size }
            item.state = settings.size == size ? .on : .off
            sizeMenu.addItem(item)
        }
        let sizeItem = NSMenuItem(title: "Size", action: nil, keyEquivalent: "")
        sizeItem.submenu = sizeMenu
        menu.addItem(sizeItem)

        let countdown = ActionItem("3-2-1 Countdown") { [weak self] in self?.settings.countdownEnabled.toggle() }
        countdown.state = settings.countdownEnabled ? .on : .off
        menu.addItem(countdown)
        menu.addItem(.separator())

        menu.addItem(ActionItem("Edit Script…") { [weak self] in
            guard let self else { return }
            editor.show(settings: settings)
        })
        menu.addItem(.separator())
        menu.addItem(ActionItem("Quit Mac Teleprompter") { NSApp.terminate(nil) })
    }

    /// Hidden main menu so ⌘C/⌘V/⌘Z/⌘A work in the editor of an LSUIElement app.
    private func installMainMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem()
        appItem.submenu = NSMenu()
        appItem.submenu?.addItem(withTitle: "Quit Mac Teleprompter", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        main.addItem(appItem)

        let editItem = NSMenuItem()
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(.separator())
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        edit.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        editItem.submenu = edit
        main.addItem(editItem)
        NSApp.mainMenu = main
    }
}

/// NSMenuItem that runs a closure; `key` is shown as a hint only (global hotkeys do the real work).
private final class ActionItem: NSMenuItem {
    private let handler: () -> Void

    init(_ title: String, key: String? = nil, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(run), keyEquivalent: "")
        target = self
        if let key {
            attributedTitle = NSAttributedString(string: "\(title)\t\(key)", attributes: [
                .paragraphStyle: { let p = NSMutableParagraphStyle(); p.tabStops = [NSTextTab(textAlignment: .right, location: 200)]; return p }(),
            ])
        }
    }

    required init(coder: NSCoder) { fatalError() }

    @objc private func run() { handler() }
}
