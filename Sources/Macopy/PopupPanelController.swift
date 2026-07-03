import Cocoa
import SwiftUI

final class PopupPanelController {

    private var panel: NSPanel?
    private let monitor: ClipboardMonitor
    private var resignObserver: NSObjectProtocol?
    private var copyObserver: NSObjectProtocol?
    private var clickMonitor: Any?
    private var isClosing = false
    private var isOpening = false
    private var targetApplication: NSRunningApplication?

    init(monitor: ClipboardMonitor) {
        self.monitor = monitor
    }

    deinit {
        teardownObservers()
    }

    func toggle() {
        if isClosing { return }
        if let panel = panel, panel.isVisible {
            closePanel()
        } else if !isOpening {
            showPanel()
        }
    }

    private func showPanel() {
        guard !isOpening, !isClosing else { return }
        isOpening = true
        targetApplication = NSWorkspace.shared.frontmostApplication

        let screenRect = targetScreenRect()
        let panelSize = preferredPanelSize(for: screenRect)
        let contentView = HistoryView(
            monitor: monitor,
            panelSize: panelSize,
            onSelect: { [weak self] item in
                self?.closePanelNow()
                self?.monitor.pasteItem(item, targetApplication: self?.targetApplication)
            },
            onClose: { [weak self] in
                self?.closePanel()
            }
        )

        let hosting = NSHostingController(rootView: contentView)
        hosting.view.wantsLayer = true

        let centeredRect = centeredRect(of: panelSize, in: screenRect)

        let panel = NSPanel(
            contentRect: centeredRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        panel.contentViewController = hosting
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.backgroundColor = .clear
        panel.isMovableByWindowBackground = false
        panel.hasShadow = true
        panel.isOpaque = false
        panel.animationBehavior = .none
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false

        setupObservers(for: panel)

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            panel.makeKey()
        }

        animateIn(panel)
        self.panel = panel
        isOpening = false
    }

    // MARK: - Observers

    private func setupObservers(for panel: NSPanel) {
        teardownObservers()

        resignObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            self?.closePanel()
        }

        copyObserver = NotificationCenter.default.addObserver(
            forName: .macopyNewCopy,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.closePanel()
        }

        clickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.closePanel()
            }
        }
    }

    private func teardownObservers() {
        if let obs = resignObserver {
            NotificationCenter.default.removeObserver(obs)
            resignObserver = nil
        }
        if let obs = copyObserver {
            NotificationCenter.default.removeObserver(obs)
            copyObserver = nil
        }
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }

    // MARK: - Close

    private func closePanel() {
        guard let p = panel, !isClosing else { return }
        isClosing = true
        teardownObservers()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            p.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            p.orderOut(nil)
            self?.panel = nil
            self?.isClosing = false
            self?.targetApplication = nil
        }
    }

    private func closePanelNow() {
        teardownObservers()
        panel?.orderOut(nil)
        panel = nil
        isClosing = false
        isOpening = false
    }

    // MARK: - Animation

    private func animateIn(_ panel: NSPanel) {
        panel.alphaValue = 0

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.22, 1, 0.36, 1)
            panel.animator().alphaValue = 1
        }
    }

    // MARK: - Positioning

    private func targetScreenRect() -> NSRect {
        let mouseLocation = NSEvent.mouseLocation
        if let screenWithMouse = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) {
            return screenWithMouse.visibleFrame
        }
        return NSScreen.main?.visibleFrame ?? NSScreen.screens.first?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
    }

    private func centeredRect(of size: NSSize, in container: NSRect) -> NSRect {
        let x = container.origin.x + max(0, (container.width - size.width) / 2)
        let y = container.origin.y + max(0, (container.height - size.height) / 2)

        let clampedX = max(container.origin.x, min(x, container.origin.x + container.width - size.width))
        let clampedY = max(container.origin.y, min(y, container.origin.y + container.height - size.height))

        return NSRect(x: clampedX, y: clampedY, width: size.width, height: size.height)
    }

    private func preferredPanelSize(for screenRect: NSRect) -> NSSize {
        NSSize(
            width: min(420, max(320, screenRect.width - 32)),
            height: min(560, max(360, screenRect.height - 32))
        )
    }
}
