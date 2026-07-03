import Cocoa

class UpdateChecker {

    static let repo = "blackowltr/Macopy"
    static let currentVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }()

    static func check(showUpToDate: Bool = false) {
        guard let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest") else { return }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("Macopy/\(currentVersion)", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String,
                  let htmlURL = json["html_url"] as? String else {
                if showUpToDate {
                    DispatchQueue.main.async {
                        showAlert(title: "Güncelleme Kontrolü",
                                  message: "Güncelleme kontrol edilemedi. İnternet bağlantını kontrol et.")
                    }
                }
                return
            }

            let remoteVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
            let isNewer = remoteVersion.compare(currentVersion, options: .numeric) == .orderedDescending

            if !isNewer {
                if showUpToDate {
                    DispatchQueue.main.async {
                        showAlert(title: "Güncelleme Kontrolü",
                                  message: "Macopy \(currentVersion) — en güncel sürümü kullanıyorsun.")
                    }
                }
                return
            }

            // Find DMG asset URL
            var dmgURL: URL?
            if let assets = json["assets"] as? [[String: Any]] {
                for asset in assets {
                    if let name = asset["name"] as? String, name.hasSuffix(".dmg"),
                       let urlStr = asset["browser_download_url"] as? String {
                        dmgURL = URL(string: urlStr)
                        break
                    }
                }
            }

            DispatchQueue.main.async {
                showUpdatePrompt(tag: tagName, version: remoteVersion, htmlURL: htmlURL, dmgURL: dmgURL)
            }
        }.resume()
    }

    static func checkSilently() {
        check(showUpToDate: false)
    }

    // MARK: - UI

    private static func showUpdatePrompt(tag: String, version: String, htmlURL: String, dmgURL: URL?) {
        let alert = NSAlert()
        alert.messageText = "Yeni Sürüm Mevcut: \(tag)"
        alert.informativeText = "Macopy \(version) yayında."
        alert.addButton(withTitle: "Güncelle ve İndir")
        if dmgURL != nil {
            alert.addButton(withTitle: "Arkaplanda İndir")
        }
        alert.addButton(withTitle: "Daha Sonra")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            if let url = URL(string: htmlURL) {
                NSWorkspace.shared.open(url)
            }
        case .alertSecondButtonReturn:
            if let url = dmgURL {
                downloadAndOpenDMG(url)
            }
        default:
            break
        }
    }

    private static func downloadAndOpenDMG(_ url: URL) {
        let task = URLSession.shared.downloadTask(with: url) { localURL, _, error in
            guard let localURL = localURL, error == nil else {
                DispatchQueue.main.async {
                    showAlert(title: "İndirme Başarısız",
                              message: "DMG indirilemedi. Tarayıcıdan indirmeyi dene.")
                }
                return
            }

            let destURL = URL(fileURLWithPath: "/tmp/Macopy-Update.dmg")
            try? FileManager.default.removeItem(at: destURL)
            try? FileManager.default.moveItem(at: localURL, to: destURL)

            DispatchQueue.main.async {
                NSWorkspace.shared.open(destURL)
                showAlert(title: "İndirme Tamamlandı",
                          message: "DMG açıldı. Macopy'yi Applications'a sürükleyip bırak.")
            }
        }
        task.resume()
    }

    private static func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "Tamam")
        alert.runModal()
    }
}
