import Cocoa
import Combine
import SwiftUI

final class ClipboardMonitor: ObservableObject {

    @Published private(set) var items: [ClipboardItem] = []

    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var timer: Timer?
    private let maxItems = 200

    private let concealedType = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
    private let transientType = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")

    private let saveQueue = DispatchQueue(label: "com.macopy.save", qos: .utility)
    private let thermalQueue = DispatchQueue(label: "com.macopy.thermal", qos: .background)

    private var isThermalThrottled = false
    private var thermalObserver: NSObjectProtocol?

    private var storageURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Macopy", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("history.json")
    }

    init() {
        loadFromDisk()
        secureStorageFile()
        startThermalMonitoring()
    }

    deinit {
        stop()
        if let obs = thermalObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    func start() {
        stop()
        let interval = currentPollInterval()
        timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // ── Battery-Aware Polling ──

    private func currentPollInterval() -> TimeInterval {
        if isThermalThrottled { return 3.0 }

        let processInfo = ProcessInfo.processInfo
        if processInfo.isLowPowerModeEnabled { return 2.0 }
        if processInfo.thermalState == .critical || processInfo.thermalState == .fair { return 2.0 }

        return 1.0
    }

    func adjustPollingForThermalState() {
        let interval = currentPollInterval()
        if let t = timer {
            t.invalidate()
            let newTimer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
                self?.checkPasteboard()
            }
            RunLoop.main.add(newTimer, forMode: .common)
            self.timer = newTimer
        }
    }

    private func startThermalMonitoring() {
        thermalObserver = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            let state = ProcessInfo.processInfo.thermalState
            self?.isThermalThrottled = (state == .critical)
            self?.adjustPollingForThermalState()
        }
    }

    // ── Clipboard Check ──

    private func checkPasteboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount

        let types = pb.types ?? []
        if types.contains(concealedType) || types.contains(transientType) {
            return
        }

        if let fileURLs = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !fileURLs.isEmpty {
            for url in fileURLs {
                addItem(ClipboardItem(fileURL: url.path))
            }
            return
        }

        if let image = NSImage(pasteboard: pb) {
            addItem(ClipboardItem(image: image))
            return
        }

        if let string = pb.string(forType: .string), !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addItem(ClipboardItem(text: string))
            return
        }
    }

    // ── Storage Limits ──

    private let maxStorageBytes = 20_000_000
    private let maxImageBytes = 2_000_000
    private let maxImageDimension: CGFloat = 1200

    private func compressedImageData(from image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }

        let w = CGFloat(bitmap.pixelsWide)
        let h = CGFloat(bitmap.pixelsHigh)
        let finalW = min(w, maxImageDimension)
        let finalH = min(h, maxImageDimension)
        let shouldResize = finalW < w || finalH < h

        let targetBitmap: NSBitmapImageRep
        if shouldResize {
            let scale = min(finalW / w, finalH / h)
            let newW = Int(w * scale)
            let newH = Int(h * scale)
            guard let cgImage = bitmap.cgImage else { return nil }
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            guard let ctx = CGContext(
                data: nil, width: newW, height: newH,
                bitsPerComponent: 8, bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return nil }
            ctx.interpolationQuality = .high
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: newW, height: newH))
            guard let resizedCG = ctx.makeImage() else { return nil }
            let resized = NSImage(cgImage: resizedCG, size: NSSize(width: newW, height: newH))
            guard let resizedTiff = resized.tiffRepresentation,
                  let resizedBitmap = NSBitmapImageRep(data: resizedTiff) else { return nil }
            targetBitmap = resizedBitmap
        } else {
            targetBitmap = bitmap
        }

        if let pngData = targetBitmap.representation(using: .png, properties: [:]),
           pngData.count <= maxImageBytes {
            return pngData
        }

        return targetBitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.6])
    }

    private func estimateStorageSize() -> Int {
        guard let data = try? JSONEncoder().encode(items) else { return 0 }
        return data.count
    }

    private func trimToStorageLimit() {
        var size = estimateStorageSize()
        while size > maxStorageBytes, let lastUnpinned = items.last(where: { !$0.isPinned }) {
            items.removeAll { $0.id == lastUnpinned.id }
            size = estimateStorageSize()
        }
    }

    // ── Add / Manage Items ──

    private func addItem(_ item: ClipboardItem) {
        if let last = items.first, last.hasSameContent(as: item) {
            return
        }

        var processedItem: ClipboardItem
        if item.type == .image, let img = item.nsImage, let compressed = compressedImageData(from: img) {
            var mutable = ClipboardItem(image: img)
            mutable.imageData = compressed
            processedItem = mutable
        } else {
            processedItem = item
        }
        processedItem.isPinned = items.first(where: { $0.hasSameContent(as: processedItem) })?.isPinned ?? false

        autoCleanOldItems()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            items.removeAll { $0.hasSameContent(as: processedItem) }
            items.insert(processedItem, at: 0)
            trimToLimit()
            trimToStorageLimit()
        }

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .macopyNewCopy, object: nil)
        }

        saveToDiskAsync()
    }

    private func trimToLimit() {
        let pinned = items.filter { $0.isPinned }
        let unpinned = items.filter { !$0.isPinned }
        if unpinned.count > maxItems {
            let trimmedUnpinned = Array(unpinned.prefix(maxItems))
            items = (pinned + trimmedUnpinned).sortedForDisplay()
        }
    }

    private func autoCleanOldItems() {
        let cutoff = Date().addingTimeInterval(-7 * 86400)
        let oldUnpinned = items.filter { !$0.isPinned && $0.date < cutoff }
        guard !oldUnpinned.isEmpty else { return }
        items.removeAll { oldUnpinned.contains($0) }
    }

    // ── User Actions ──

    func togglePin(_ item: ClipboardItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
            items[idx].isPinned.toggle()
            items = items.sortedForDisplay()
        }
        saveToDiskAsync()
    }

    func delete(_ item: ClipboardItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            items.removeAll { $0.id == item.id }
        }
        saveToDiskAsync()
    }

    func clearHistory() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            items.removeAll { !$0.isPinned }
        }
        saveToDiskAsync()
    }

    // ── Paste ──

    func pasteItem(_ item: ClipboardItem, targetApplication: NSRunningApplication? = nil) {
        let pb = NSPasteboard.general
        pb.clearContents()

        switch item.type {
        case .text:
            pb.setString(item.textValue ?? "", forType: .string)
        case .fileURL:
            if let path = item.textValue {
                let url = URL(fileURLWithPath: path)
                pb.writeObjects([url as NSURL])
            }
        case .image:
            if let img = item.nsImage {
                pb.writeObjects([img])
            }
        }

        lastChangeCount = pb.changeCount
        PasteSimulator.simulatePaste(into: targetApplication)
    }

    // ── Persistence ──

    private func saveToDiskAsync() {
        let url = storageURL
        let snapshot = items
        saveQueue.async {
            do {
                let data = try JSONEncoder().encode(snapshot)
                try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            } catch {
                print("Geçmiş kaydedilemedi: \(error)")
            }
        }
    }

    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: storageURL) else { return }
        if let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            items = decoded.sortedForDisplay()
        }
        autoCleanOldItems()
    }

    private func secureStorageFile() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: storageURL.path)
            let permissions = attributes[.posixPermissions] as? Int ?? 0o644
            if permissions & 0o007 != 0 {
                try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: storageURL.path)
            }
        } catch {
            print("Dosya izinleri ayarlanamadı: \(error)")
        }
    }
}

extension Notification.Name {
    static let macopyNewCopy = Notification.Name("macopyNewCopy")
}

private extension ClipboardItem {
    func hasSameContent(as other: ClipboardItem) -> Bool {
        type == other.type &&
            textValue == other.textValue &&
            imageData == other.imageData
    }
}

private extension Array where Element == ClipboardItem {
    func sortedForDisplay() -> [ClipboardItem] {
        sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.date > $1.date
        }
    }
}
