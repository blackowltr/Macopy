#!/bin/bash
set -e

PRODUCT_NAME="Macopy"
BUILD_DIR=".build"
APP_NAME="${PRODUCT_NAME}.app"
APP_PATH="${BUILD_DIR}/${APP_NAME}"

echo "==> Building ${PRODUCT_NAME} (release)..."
swift build -c release

echo "==> Creating .app bundle..."
rm -rf "${APP_PATH}"
mkdir -p "${APP_PATH}/Contents/MacOS"
mkdir -p "${APP_PATH}/Contents/Resources"

cp "${BUILD_DIR}/release/${PRODUCT_NAME}" "${APP_PATH}/Contents/MacOS/"
cp "Info.plist" "${APP_PATH}/Contents/"
cp "Resources/AppIcon.icns" "${APP_PATH}/Contents/Resources/"

BINARY="${APP_PATH}/Contents/MacOS/${PRODUCT_NAME}"

echo "==> Signing with ad-hoc signature..."
if codesign --force --deep --sign - "${APP_PATH}" 2>/dev/null; then
    echo "     İmzalama başarılı"
else
    echo "     İmzalama atlandı (gerekli değil)"
fi

echo "==> Removing quarantine attribute..."
xattr -cr "${APP_PATH}" 2>/dev/null || true

echo ""
echo "  ✅  ${APP_NAME} oluşturuldu"
echo "  📁  ${PWD}/${APP_PATH}"
echo ""
echo "  Uygulamayı /Applications/ klasörüne taşımak için:"
echo "  cp -R \"${APP_PATH}\" /Applications/"
echo ""
echo "  Uygulamayı çalıştırmak için:"
echo "  open \"${APP_PATH}\""
echo ""
