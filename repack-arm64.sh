#!/bin/bash
# Repackage Proton Mail desktop (amd64 .deb) for ARM64 Linux
# Usage: ./repack-arm64.sh [version]
# Example: ./repack-arm64.sh 1.13.4

set -euo pipefail

VERSION="${1:-1.13.4}"
ELECTRON_VERSION="42.8.0"
DEB_URL="https://proton.me/download/mail/linux/ProtonMail-desktop-beta.deb"
ELECTRON_URL="https://github.com/electron/electron/releases/download/v${ELECTRON_VERSION}/electron-v${ELECTRON_VERSION}-linux-arm64.zip"

DEB_FILE="proton-mail-${VERSION}-amd64.deb"
ELECTRON_ZIP="electron-v${ELECTRON_VERSION}-linux-arm64.zip"
EXTRACT_DIR="deb-extract"
ELECTRON_DIR="electron-arm64"
OUTPUT_DEB="proton-mail_${VERSION}_arm64.deb"

echo "=== Proton Mail ARM64 Repackager ==="
echo "Version: ${VERSION}"
echo "Electron: ${ELECTRON_VERSION}"
echo ""

# Download sources
if [[ ! -f "${DEB_FILE}" ]]; then
    echo "[1/6] Downloading official amd64 .deb..."
    curl -fsSL -o "${DEB_FILE}" "${DEB_URL}"
else
    echo "[1/6] Using cached ${DEB_FILE}"
fi

if [[ ! -f "${ELECTRON_ZIP}" ]]; then
    echo "[2/6] Downloading Electron ${ELECTRON_VERSION} ARM64..."
    curl -fsSL -o "${ELECTRON_ZIP}" "${ELECTRON_URL}"
else
    echo "[2/6] Using cached ${ELECTRON_ZIP}"
fi

# Extract
echo "[3/6] Extracting .deb..."
rm -rf "${EXTRACT_DIR}"
mkdir -p "${EXTRACT_DIR}"
dpkg-deb -R "${DEB_FILE}" "${EXTRACT_DIR}/"

echo "[4/6] Extracting Electron ARM64..."
rm -rf "${ELECTRON_DIR}"
mkdir -p "${ELECTRON_DIR}"
unzip -q "${ELECTRON_ZIP}" -d "${ELECTRON_DIR}/"

# Find the app directory (contains the Electron runtime)
APP_DIR=$(find "${EXTRACT_DIR}/usr/lib" -maxdepth 1 -type d -name "proton*" | head -1)
if [[ -z "${APP_DIR}" ]]; then
    echo "ERROR: Could not find Proton Mail app directory in .deb"
    exit 1
fi

echo "[5/6] Swapping x64 binaries for ARM64..."
# Main binary (name may contain spaces)
MAIN_BIN=$(find "${APP_DIR}" -maxdepth 1 -type f -executable ! -name "*.so*" ! -name "chrome-*" ! -name "chrome_crashpad_handler" | head -1)
if [[ -n "${MAIN_BIN}" ]]; then
    cp "${ELECTRON_DIR}/electron" "${MAIN_BIN}"
fi

# Shared libraries and support files
for f in chrome_crashpad_handler chrome-sandbox libEGL.so libGLESv2.so libffmpeg.so \
         libvk_swiftshader.so libvulkan.so.1 icudtl.dat resources.pak snapshot_blob.bin \
         v8_context_snapshot.bin vk_swiftshader_icd.json chrome_100_percent.pak chrome_200_percent.pak; do
    if [[ -f "${ELECTRON_DIR}/${f}" ]]; then
        cp "${ELECTRON_DIR}/${f}" "${APP_DIR}/"
    fi
done

# Locales
if [[ -d "${ELECTRON_DIR}/locales" ]]; then
    cp -r "${ELECTRON_DIR}/locales" "${APP_DIR}/"
fi

# Patch control file
echo "[6/6] Patching DEBIAN/control and rebuilding..."
sed -i 's/^Architecture: amd64$/Architecture: arm64/' "${EXTRACT_DIR}/DEBIAN/control"

# Recalculate installed size
INSTALLED_SIZE=$(du -sk "${EXTRACT_DIR}/usr" | cut -f1)
sed -i "s/^Installed-Size: .*/Installed-Size: ${INSTALLED_SIZE}/" "${EXTRACT_DIR}/DEBIAN/control"

# Regenerate md5sums
if [[ -f "${EXTRACT_DIR}/DEBIAN/md5sums" ]]; then
    (cd "${EXTRACT_DIR}" && find usr -type f -exec md5sum {} + > DEBIAN/md5sums)
fi

# Fix permissions
chmod 755 "${APP_DIR}/chrome-sandbox" 2>/dev/null || true
chmod 4755 "${APP_DIR}/chrome-sandbox" 2>/dev/null || true

# Build
dpkg-deb --root-owner-group --build "${EXTRACT_DIR}" "${OUTPUT_DEB}"

echo ""
echo "=== Done ==="
echo "Output: ${OUTPUT_DEB}"
echo "Install: sudo dpkg -i ${OUTPUT_DEB}"
