#!/bin/bash
set -e

# ── Versiyon bilgisi ──
VERSION="${1:-1.0.0}"
APP_NAME="Macopy"
SITE_DIR="site"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

echo "==> Site için DMG oluşturuluyor..."

# 1. Uygulamayı derle
bash build.sh

# 2. DMG oluştur (yalnızca .app)
rm -f "${SITE_DIR}/${DMG_NAME}"
hdiutil create -volname "${APP_NAME}" \
    -srcfolder ".build/${APP_NAME}.app" \
    -ov -format UDZO \
    "${SITE_DIR}/${DMG_NAME}"

echo ""
echo "  ✅  ${SITE_DIR}/${DMG_NAME} oluşturuldu"
echo ""

# 3. Versiyon bilgilerini güncelle
echo "==> Site versiyonları güncelleniyor..."

sed -i '' "s|v[0-9]*\.[0-9]*\.[0-9]*|v${VERSION}|g" "${SITE_DIR}/index.html"
sed -i '' "s|${APP_NAME}-[0-9]*\.[0-9]*\.[0-9]*\.dmg|${DMG_NAME}|g" "${SITE_DIR}/index.html"

echo "  ✅  index.html güncellendi (v${VERSION})"
echo ""
echo "  Siteyi test et: open ${SITE_DIR}/index.html"
echo "  GitHub'a yükle: github.com/blackowltr/Macopy"
echo ""
