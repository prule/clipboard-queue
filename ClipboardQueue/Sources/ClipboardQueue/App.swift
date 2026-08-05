import SwiftUI
import AppKit
import Carbon.HIToolbox
import Combine

@main
struct ClipboardQueueApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        // The main window and the menu-bar popover are both driven from the
        // delegate so they can share one store and one exact 1000×640 window.
        Settings {
            SettingsSheet().environmentObject(AppStore.shared)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = AppStore.shared
    private var mainWindow: NSWindow?
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        buildMainMenu()
        buildMainWindow()
        buildStatusItem()
        registerHotKeys()

        store.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshStatusItem() }
            .store(in: &cancellables)

        refreshStatusItem()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }

    // MARK: - Main window

    private func buildMainWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Clipboard Queue"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = .white
        window.appearance = NSAppearance(named: .aqua)   // the design is a light-mode spec
        window.isReleasedWhenClosed = false

        // The design draws its own traffic lights inside the sidebar header.
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        let host = NSHostingView(rootView: MainWindowView().environmentObject(store))
        host.frame = NSRect(x: 0, y: 0, width: 1000, height: 640)
        window.contentView = host
        window.setContentSize(NSSize(width: 1000, height: 640))
        window.center()

        mainWindow = window
        window.makeKeyAndOrderFront(nil)
    }

    func showMainWindow() {
        if mainWindow == nil { buildMainWindow() }
        NSApp.activate(ignoringOtherApps: true)
        mainWindow?.makeKeyAndOrderFront(nil)
    }

    // MARK: - Menu bar

    private func buildStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.action = #selector(togglePopover)
        item.button?.target = self
        statusItem = item

        let popover = NSPopover()
        popover.behavior = .transient
        popover.appearance = NSAppearance(named: .aqua)
        popover.contentViewController = NSHostingController(
            rootView: MenuBarRoot(openMainWindow: { [weak self] in
                self?.popover?.performClose(nil)
                self?.showMainWindow()
            }).environmentObject(store)
        )
        self.popover = popover
    }

    /// `▤ 4/20` in the accent colour, matching the mock's menu-bar strip.
    private func refreshStatusItem() {
        guard let button = statusItem?.button else { return }
        let color = store.running
            ? NSColor(Color(hex: store.accent.hex))
            : NSColor(Theme.pausedButton)
        button.attributedTitle = NSAttributedString(
            string: "▤ \(store.counterShort)",
            attributes: [
                .font: Theme.nsMono(11, .medium),
                .foregroundColor: color
            ]
        )
    }

    @objc private func togglePopover() {
        guard let popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - Global hot keys

    private func registerHotKeys() {
        let center = HotKeyCenter.shared
        center.register(id: HotKey.skip, keyCode: kVK_RightArrow, modifiers: HotKey.controlOption) { [weak self] in
            self?.store.advance()
        }
        center.register(id: HotKey.back, keyCode: kVK_LeftArrow, modifiers: HotKey.controlOption) { [weak self] in
            self?.store.back()
        }
        center.register(id: HotKey.openWindow, keyCode: kVK_ANSI_C, modifiers: HotKey.controlOption) { [weak self] in
            self?.showMainWindow()
        }
    }

    // MARK: - App menu

    private func buildMainMenu() {
        let main = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Clipboard Queue",
                        action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
            .target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide Clipboard Queue", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Quit Clipboard Queue", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        main.addItem(appItem)

        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu
        main.addItem(editItem)

        let queueItem = NSMenuItem()
        let queueMenu = NSMenu(title: "Queue")
        add(queueMenu, "Next item", #selector(menuAdvance), "]")
        add(queueMenu, "Back", #selector(menuBack), "[")
        add(queueMenu, "Reset", #selector(menuReset), "r")
        queueMenu.addItem(.separator())
        add(queueMenu, "Open Main Window", #selector(menuOpenWindow), "0")
        queueItem.submenu = queueMenu
        main.addItem(queueItem)

        NSApp.mainMenu = main
    }

    private func add(_ menu: NSMenu, _ title: String, _ action: Selector, _ key: String) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        menu.addItem(item)
    }

    @objc private func menuAdvance() { store.advance() }
    @objc private func menuBack() { store.back() }
    @objc private func menuReset() { store.reset() }
    @objc private func menuOpenWindow() { showMainWindow() }

    @objc private func openSettings() {
        if #available(macOS 14, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
    }
}
