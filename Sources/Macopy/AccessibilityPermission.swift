import Cocoa

enum AccessibilityPermission {

    static func requestIfNeeded() {
        let options: [String: Any] = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }
}
