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
                  let releaseURL = json["html_url"] as? String else {
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

            DispatchQueue.main.async {
                if isNewer {
                    let alert = NSAlert()
                    alert.messageText = "Yeni Sürüm Mevcut: \(tagName)"
                    alert.informativeText = "Macopy \(remoteVersion) yayında. Şimdi güncelle?"
                    alert.addButton(withTitle: "İndir")
                    alert.addButton(withTitle: "Daha Sonra")
                    if alert.runModal() == .alertFirstButtonReturn {
                        if let url = URL(string: releaseURL) {
                            NSWorkspace.shared.open(url)
                        }
                    }
                } else if showUpToDate {
                    showAlert(title: "Güncelleme Kontrolü",
                              message: "Macopy \(currentVersion) — en güncel sürümü kullanıyorsun.")
                }
            }
        }.resume()
    }

    static func checkSilently() {
        check(showUpToDate: false)
    }

    private static func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "Tamam")
        alert.runModal()
    }
}
