import Cocoa

enum PasteSimulator {

    static func simulatePaste() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            guard let source = CGEventSource(stateID: .combinedSessionState) else { return }

            let vKeyCode: CGKeyCode = 9

            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
            keyDown?.flags = .maskCommand
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
            keyUp?.flags = .maskCommand

            let loc = CGEventTapLocation.cghidEventTap
            keyDown?.post(tap: loc)
            keyUp?.post(tap: loc)
        }
    }
}
