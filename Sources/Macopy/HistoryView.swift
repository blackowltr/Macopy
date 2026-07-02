import SwiftUI

// MARK: - Theme

private enum Theme {
    static let accentBlue = Color(nsColor: NSColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 1))
    static let accentPurple = Color(nsColor: NSColor(red: 0.75, green: 0.35, blue: 0.95, alpha: 1))
    static let accentOrange = Color(nsColor: NSColor(red: 1.0, green: 0.62, blue: 0.04, alpha: 1))
    static let accentGreen = Color(nsColor: NSColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1))
    static let accentRed = Color(nsColor: NSColor(red: 1.0, green: 0.27, blue: 0.23, alpha: 1))
    static let accentYellow = Color(nsColor: NSColor(red: 1.0, green: 0.84, blue: 0.04, alpha: 1))

    static let surfacePrimary = Color(nsColor: .controlBackgroundColor)
    static let surfaceSecondary = Color(nsColor: .windowBackgroundColor)
    static let textPrimary = Color(nsColor: .labelColor)
    static let textSecondary = Color(nsColor: .secondaryLabelColor)
    static let textTertiary = Color(nsColor: .tertiaryLabelColor)
    static let separator = Color(nsColor: .separatorColor)
}

// MARK: - HistoryView

struct HistoryView: View {
    @ObservedObject var monitor: ClipboardMonitor
    var onSelect: (ClipboardItem) -> Void
    var onClose: () -> Void

    @State private var searchText = ""
    @State private var copiedItemId: UUID?
    @FocusState private var isSearchFocused: Bool

    private var searchResults: [ClipboardItem] {
        let sorted = monitor.items.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned }
            return a.date > b.date
        }
        guard !searchText.isEmpty else { return Array(sorted.prefix(100)) }
        return sorted.filter {
            $0.previewText.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var sections: [(String, [ClipboardItem])] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var pinned: [ClipboardItem] = []
        var todayItems: [ClipboardItem] = []
        var yesterdayItems: [ClipboardItem] = []
        var olderItems: [ClipboardItem] = []

        for item in searchResults {
            if item.isPinned { pinned.append(item); continue }
            let diff = cal.dateComponents([.day], from: cal.startOfDay(for: item.date), to: today).day ?? 0
            switch diff {
            case 0: todayItems.append(item)
            case 1: yesterdayItems.append(item)
            default: olderItems.append(item)
            }
        }

        var result: [(String, [ClipboardItem])] = []
        if !pinned.isEmpty { result.append(("Sabitlenenler", pinned)) }
        if !todayItems.isEmpty { result.append(("Bugün", todayItems)) }
        if !yesterdayItems.isEmpty { result.append(("Dün", yesterdayItems)) }
        if !olderItems.isEmpty { result.append(("Geçmiş", olderItems)) }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            searchBarSection
            if sections.isEmpty {
                emptyState
            } else {
                listSection
            }
        }
        .frame(width: 420, height: 560)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.35), radius: 50, x: 0, y: 15)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isSearchFocused = true
            }
        }
        .onExitCommand { onClose() }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.accentBlue)
                        .frame(width: 28, height: 28)
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("Macopy")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
            }

            Spacer()

                Text("⌘B")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Theme.separator, lineWidth: 0.5)
                )
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 14)
    }

    // MARK: - Search

    private var searchBarSection: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textSecondary)

                TextField("Kopyalananları ara…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .focused($isSearchFocused)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        isSearchFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                    .foregroundColor(Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Theme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSearchFocused ? Theme.accentBlue.opacity(0.5) : Theme.separator, lineWidth: 1)
            )
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
        .animation(.easeOut(duration: 0.15), value: isSearchFocused)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(searchText.isEmpty ? Theme.accentBlue.opacity(0.15) : Theme.accentPurple.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: searchText.isEmpty ? "clipboard" : "magnifyingglass")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(searchText.isEmpty ? Theme.accentBlue : Theme.accentPurple)
            }

            VStack(spacing: 6) {
                Text(searchText.isEmpty ? "Henüz bir şey kopyalamadın" : "Sonuç bulunamadı")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)

                if !searchText.isEmpty {
                    Text("\u{201C}\(searchText)\u{201D} için eşleşme yok")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary)
                } else {
                    Text("Bir şey kopyaladığında burada görünecek")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - List

    private var listSection: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(sections.indices, id: \.self) { sectionIdx in
                        let (title, items) = sections[sectionIdx]

                        sectionHeader(title, count: items.count)
                            .padding(.top, sectionIdx == 0 ? 4 : 10)

                        ForEach(items) { item in
                            ItemRow(
                                item: item,
                                copiedItemId: $copiedItemId,
                                onSelect: { selectItem(item) },
                                onPin: { monitor.togglePin(item) },
                                onDelete: { monitor.delete(item) }
                            )
                            .id(item.id)
                            .padding(.horizontal, 14)
                            .padding(.top, 4)
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .scale(scale: 0.92).combined(with: .opacity)
                            ))
                        }
                    }
                }
                .padding(.bottom, 16)
            }
            .animation(.easeInOut(duration: 0.2), value: searchText)
        }
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.textSecondary)
                .tracking(0.8)

            Text("\(count)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Theme.accentBlue)
                .clipShape(Capsule())

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }

    private func selectItem(_ item: ClipboardItem) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            copiedItemId = item.id
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onSelect(item)
        }
    }
}

// MARK: - ItemRow

private struct ItemRow: View {
    let item: ClipboardItem
    @Binding var copiedItemId: UUID?
    let onSelect: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            iconView

            VStack(alignment: .leading, spacing: 4) {
                Text(item.previewText)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .lineLimit(2)
                    .foregroundColor(Theme.textPrimary)

                HStack(spacing: 8) {
                    Label(item.typeLabel, systemImage: item.typeIconSmall)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(item.typeColor.opacity(0.9))

                    Circle()
                        .fill(item.typeColor.opacity(0.4))
                        .frame(width: 3, height: 3)

                    Text(item.timeAgo)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.textTertiary)
                }
            }

            Spacer(minLength: 6)

            if copiedItemId == item.id {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.accentGreen)
                    .transition(.scale.combined(with: .opacity))
            } else if isHovering {
                HStack(spacing: 2) {
                    actionButton(icon: "pin", color: item.isPinned ? Theme.accentYellow : Theme.textTertiary, action: onPin)
                    actionButton(icon: "xmark.circle", color: Theme.accentRed, action: onDelete)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.accentYellow)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(rowBorder)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: copiedItemId == item.id)
    }

    private var rowBackground: some View {
        Group {
            if copiedItemId == item.id {
                Theme.accentGreen.opacity(0.15)
            } else if isHovering {
                item.typeColor.opacity(0.12)
            } else {
                Theme.surfacePrimary.opacity(0.85)
            }
        }
    }

    private var rowBorder: some View {
        Group {
            if copiedItemId == item.id {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.accentGreen.opacity(0.6), lineWidth: 1.5)
            } else if isHovering {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(item.typeColor.opacity(0.35), lineWidth: 1)
            }
        }
    }

    private func actionButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var iconView: some View {
        switch item.type {
        case .text:
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.accentBlue.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: "text.alignleft")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.accentBlue)
            }

        case .fileURL:
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.accentOrange.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: "folder.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.accentOrange)
            }

        case .image:
            if let nsImage = item.nsImage {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.accentPurple.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: "photo.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.accentPurple)
                }
            }
        }
    }
}

// MARK: - Extensions

private extension ClipboardItem {
    var typeLabel: String {
        switch type {
        case .text: return "Metin"
        case .fileURL: return "Dosya"
        case .image: return "Resim"
        }
    }

    var typeIconSmall: String {
        switch type {
        case .text: return "doc.text"
        case .fileURL: return "folder"
        case .image: return "photo"
        }
    }

    var typeColor: Color {
        switch type {
        case .text: return Theme.accentBlue
        case .fileURL: return Theme.accentOrange
        case .image: return Theme.accentPurple
        }
    }
}
