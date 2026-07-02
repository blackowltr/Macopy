# Macopy

Windows'taki **Win+V** pano geçmişi özelliğinin macOS karşılığı. Menü çubuğunda yaşayan, `⌘B` ile açılan hafif bir pano geçmişi uygulaması.

![Platform](https://img.shields.io/badge/platform-macOS%2012%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![Architecture](https://img.shields.io/badge/arch-Apple%20Silicon%20%7C%20Intel-blue)

## 🌐 İnternet Sitesi

**[Macopy'yi İndir](https://baris.github.io/Macopy/)** — Landing page, DMG indirme, kurulum rehberi.

## Özellikler

- `⌘B` ile ekranın ortasında açılan modern panel
- Metin, resim ve dosya kopyalamalarını otomatik izler
- Aramalı liste, sabitleme (pin), silme
- Section'lar: Sabitlenenler, Bugün, Dün, Geçmiş
- Renkli kategoriler: Metin (mavi), Dosya (turuncu), Resim (mor)
- Yeni kopyalama veya dışarı tıklayınca otomatik kapanma
- Parola yöneticilerinden gelen hassas içeriği hariç tutar (`org.nspasteboard` standardı)
- Pil dostu: Akıllı polling, termal yönetim, arkaplan optimizasyonu
- %100 gizli: Bulut yok, hesap yok, veriler cihazdan çıkmaz
- Apple Silicon ve Intel ile uyumlu

## Kurulum

### Homebrew (Önerilen)

```bash
brew tap baris/tap
brew install --cask macopy
```

### Doğrudan İndirme

1. [GitHub Releases](https://github.com/blackowltr/Macopy/releases)'ten DMG'yi indir
2. DMG'yi aç
3. **Install.command** dosyasına çift tıkla — otomatik kurar ve açar

> Manuel kurulum: Macopy'yi sürükle-bırak ile Applications'a kopyala, sonra terminalde `xattr -cr /Applications/Macopy.app` çalıştır.

### Kaynaktan Derleme

```bash
git clone https://github.com/blackowltr/Macopy.git
cd Macopy
bash build.sh
open .build/Macopy.app
```

## İlk Çalıştırma

1. Uygulama menü çubuğunda 📋 ikonuyla görünür
2. İlk çalıştırmada **System Settings > Privacy & Security > Accessibility** izni istenir
3. İzni ver, ⌘B ile paneli aç

> **Not:** macOS "güvenilmeyen geliştirici" uyarısı verirse, uygulamaya sağ tıklayıp "Open" seçin veya terminalde: `xattr -cr /Applications/Macopy.app`

## Kullanım

| Kısayol | İşlev |
|---------|-------|
| `⌘B` | Panoyu aç/kapat |
| `⌘C` | Kopyala (otomatik kaydedilir) |
| `ESC` | Paneli kapat |

- Biröğeye tıklayınca panoya kopyalanır ve aktif uygulamaya yapıştırılır
- Üzerine gelince sabitleme ve silme butonları görünür
- Arama çubuğuyla geçmişinde ara

## Proje Yapısı

```
Macopy/
├── Package.swift                    # SPM build sistemi
├── build.sh                         # Tek tuşla .app oluşturma
├── site/                            # İnternet sitesi
│   ├── index.html                   # Landing page
│   └── build-site.sh                # DMG + site güncelleme
├── Sources/Macopy/
│   ├── App.swift                    # Menü bar uygulaması
│   ├── ClipboardItem.swift          # Veri modeli
│   ├── ClipboardMonitor.swift       # Pano izleme, depolama
│   ├── HistoryView.swift            # SwiftUI arayüzü
│   ├── PopupPanelController.swift   # Animasyonlu panel
│   ├── HotkeyManager.swift          # Carbon kısayol (⌘B)
│   ├── PasteSimulator.swift         # Cmd+V simülasyonu
│   ├── AccessibilityPermission.swift
│   └── VisualEffectView.swift       # NSVisualEffectView wrapper
└── Info.plist
```

## Güncelleme

Yeni sürüm yayınlamak için:

```bash
# 1. Versiyonu güncelle (site + Info.plist)
# 2. DMG oluştur ve siteyi güncelle
bash site/build-site.sh 1.1.0

# 3. GitHub'a yükle
git add . && git commit -m "v1.1.0"
git tag v1.1.0 && git push --tags
```

## Dağıtım

```bash
# Ad-hoc imzalı (zaten build.sh'de var)
codesign --force --sign - .build/Macopy.app

# Developer ID ile (App Store dışı dağıtım)
codesign --deep --force --options runtime \
    --sign "Developer ID Application: Adın" \
    .build/Macopy.app

# Notarize
xcrun notarytool submit .build/Macopy.zip \
    --apple-id "mail@ornek.com" \
    --team-id "TEAMID" \
    --password "app-specific-password" \
    --wait

xcrun stapler staple .build/Macopy.app
```

## Gizlilik

Bu uygulama hiçbir veriyi internete göndermez. Pano geçmişi yalnızca yerel diskte
(`~/Library/Application Support/Macopy/history.json`) saklanır. Dosya izinleri `600` (sadece kullanıcı) ile ayarlanmıştır.

## Lisans

MIT — detaylar için [LICENSE](LICENSE) dosyasına bakabilirsin.
