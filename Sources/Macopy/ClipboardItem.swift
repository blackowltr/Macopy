import Cocoa

enum ClipboardItemType: String, Codable {
    case text
    case image
    case fileURL
}

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let type: ClipboardItemType
    let textValue: String?
    var imageData: Data?
    let date: Date
    var isPinned: Bool = false

    init(text: String) {
        self.id = UUID()
        self.type = .text
        self.textValue = text
        self.imageData = nil
        self.date = Date()
    }

    init(fileURL: String) {
        self.id = UUID()
        self.type = .fileURL
        self.textValue = fileURL
        self.imageData = nil
        self.date = Date()
    }

    init(image: NSImage) {
        self.id = UUID()
        self.type = .image
        self.textValue = nil
        self.imageData = image.tiffRepresentation.flatMap {
            NSBitmapImageRep(data: $0)?.representation(using: .png, properties: [:])
        }
        self.date = Date()
    }

    var previewText: String {
        switch type {
        case .text:
            let t = textValue ?? ""
            return t.count > 150 ? String(t.prefix(150)) + "\u{2026}" : t
        case .fileURL:
            return (textValue as NSString?)?.lastPathComponent ?? "Dosya"
        case .image:
            return "Resim"
        }
    }

    var nsImage: NSImage? {
        guard let data = imageData else { return nil }
        return NSImage(data: data)
    }

    var timeAgo: String {
        let interval = Date().timeIntervalSince(date)
        switch interval {
        case ..<60: return "şimdi"
        case ..<3600: return "\(Int(interval / 60))d"
        case ..<86400: return "\(Int(interval / 3600))s"
        case ..<604800: return "\(Int(interval / 86400))g"
        default: return date.formatted(date: .numeric, time: .shortened)
        }
    }
}
