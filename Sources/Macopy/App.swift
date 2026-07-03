import Cocoa
import SwiftUI
import ServiceManagement

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    var statusItem: NSStatusItem!
    var monitor: ClipboardMonitor!
    var hotkeyManager: HotkeyManager!
    var popupController: PopupPanelController!

    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        AccessibilityPermission.requestIfNeeded()
        setupMonitor()
        setupHotkey()
        observeSleepWake()
        registerLoginItemIfNeeded()

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            UpdateChecker.checkSilently()
        }
    }

    // MARK: - Status Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: 28)
        if let button = statusItem.button {
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            let image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Macopy")
            button.image = image?.withSymbolConfiguration(config)
            button.toolTip = "Macopy - Pano Geçmişi (⌘B)"
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: "Panoyu Aç (⌘B)",
            action: #selector(togglePopup),
            keyEquivalent: ""
        ))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: "Son Kopyayı Yapıştır",
            action: #selector(pasteLastCopy),
            keyEquivalent: ""
        ))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: "Geçmişi Temizle",
            action: #selector(clearHistory),
            keyEquivalent: ""
        ))
        menu.addItem(NSMenuItem.separator())

        let autoLaunchItem = NSMenuItem(
            title: "Otomatik Başlat",
            action: #selector(toggleAutoLaunch),
            keyEquivalent: ""
        )
        autoLaunchItem.state = isLoginItemEnabled() ? .on : .off
        menu.addItem(autoLaunchItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: "Güncellemeleri Kontrol Et",
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        ))
        menu.addItem(NSMenuItem(
            title: "Macopy Hakkında",
            action: #selector(showAbout),
            keyEquivalent: ""
        ))
        menu.addItem(NSMenuItem(
            title: "Çıkış",
            action: #selector(quit),
            keyEquivalent: "q"
        ))
        statusItem.menu = menu
    }

    // MARK: - Monitor & Hotkey

    private func setupMonitor() {
        monitor = ClipboardMonitor()
        monitor.start()
    }

    private func setupHotkey() {
        popupController = PopupPanelController(monitor: monitor)

        hotkeyManager = HotkeyManager { [weak self] in
            self?.popupController.toggle()
        }
        hotkeyManager.register()
    }

    // MARK: - Sleep / Wake

    private func observeSleepWake() {
        let nc = NSWorkspace.shared.notificationCenter
        sleepObserver = nc.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.hotkeyManager?.unregister()
        }
        wakeObserver = nc.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.hotkeyManager?.register()
            self?.monitor?.adjustPollingForThermalState()
        }
    }

    deinit {
        if let obs = sleepObserver { NSWorkspace.shared.notificationCenter.removeObserver(obs) }
        if let obs = wakeObserver { NSWorkspace.shared.notificationCenter.removeObserver(obs) }
    }

    // MARK: - Login Item

    private func registerLoginItemIfNeeded() {
        if !isLoginItemEnabled() { return }
        enableLoginItem()
    }

    private func isLoginItemEnabled() -> Bool {
        UserDefaults.standard.bool(forKey: "launchAtLogin")
    }

    private func enableLoginItem() {
        if #available(macOS 13.0, *) {
            try? SMAppService.mainApp.register()
        }
    }

    private func disableLoginItem() {
        if #available(macOS 13.0, *) {
            try? SMAppService.mainApp.unregister()
        }
    }

    @objc private func toggleAutoLaunch(_ sender: NSMenuItem) {
        let newState = sender.state != .on
        sender.state = newState ? .on : .off
        UserDefaults.standard.set(newState, forKey: "launchAtLogin")
        if newState {
            enableLoginItem()
        } else {
            disableLoginItem()
        }
    }

    // MARK: - Actions

    @objc func togglePopup() {
        popupController.toggle()
    }

    @objc func pasteLastCopy() {
        guard let first = monitor.items.first else { return }
        monitor.pasteItem(first)
    }

    @objc func clearHistory() {
        monitor.clearHistory()
    }

    @objc func showAbout() {
        NSApplication.shared.orderFrontStandardAboutPanel(nil)
    }

    @objc func checkForUpdates() {
        UpdateChecker.check(showUpToDate: true)
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}
