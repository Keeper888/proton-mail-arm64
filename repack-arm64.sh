#!/bin/bash
# Repackage Proton Mail desktop (amd64 .deb) for ARM64 Linux
# Usage: ./repack-arm64.sh [version]
#   No version  -> latest stable from Proton's release feed
#   Example:    ./repack-arm64.sh 1.14.0
#
# The Electron version is detected from the official .deb, so the ARM64
# runtime always matches what Proton shipped.

set -euo pipefail

FEED_URL="https://proton.me/download/mail/linux/version.json"

need() { command -v "$1" >/dev/null || { echo "ERROR: '$1' is required (sudo apt install $2)"; exit 1; }; }
need curl curl
need unzip unzip
need dpkg-deb dpkg
need python3 python3

echo "=== Proton Mail ARM64 Repackager ==="

# Resolve version + checksum from Proton's release feed
FEED=$(curl -fsSL "${FEED_URL}")
read -r VERSION DEB_URL DEB_SHA512 < <(printf '%s' "${FEED}" | python3 -c '
import json, sys
want = sys.argv[1]
rel = [r for r in json.load(sys.stdin)["Releases"] if r.get("CategoryName") == "Stable"]
if want:
    rel = [r for r in rel if r["Version"] == want]
if not rel:
    sys.exit("version not found in feed")
r = rel[0]
f = next(f for f in r["File"] if f["Url"].endswith(".deb"))
print(r["Version"], f["Url"], f["Sha512CheckSum"])
' "${1:-}")

DEB_FILE="proton-mail-${VERSION}-amd64.deb"
EXTRACT_DIR="deb-extract"
ELECTRON_DIR="electron-arm64"
OUTPUT_DEB="proton-mail_${VERSION}_arm64.deb"

echo "Version: ${VERSION}"

# Download + verify the official .deb
if [[ ! -f "${DEB_FILE}" ]]; then
    echo "[1/6] Downloading official amd64 .deb..."
    curl -fsSL -o "${DEB_FILE}" "${DEB_URL}"
else
    echo "[1/6] Using cached ${DEB_FILE}"
fi
echo "${DEB_SHA512}  ${DEB_FILE}" | sha512sum -c --quiet \
    || { echo "ERROR: SHA512 mismatch for ${DEB_FILE}"; rm -f "${DEB_FILE}"; exit 1; }
echo "      SHA512 verified against Proton's release feed"

# Extract
echo "[2/6] Extracting .deb..."
rm -rf "${EXTRACT_DIR}"
mkdir -p "${EXTRACT_DIR}"
dpkg-deb -R "${DEB_FILE}" "${EXTRACT_DIR}/"

# Find the app directory (contains the Electron runtime)
APP_DIR=$(find "${EXTRACT_DIR}/usr/lib" -maxdepth 1 -type d -name "proton*" | head -1)
if [[ -z "${APP_DIR}" ]]; then
    echo "ERROR: Could not find Proton Mail app directory in .deb"
    exit 1
fi

# Match the Electron version Proton bundled
ELECTRON_VERSION="${ELECTRON_VERSION:-$(tr -d '[:space:]' < "${APP_DIR}/version")}"
ELECTRON_ZIP="electron-v${ELECTRON_VERSION}-linux-arm64.zip"
ELECTRON_BASE="https://github.com/electron/electron/releases/download/v${ELECTRON_VERSION}"
echo "Electron: ${ELECTRON_VERSION}"

if [[ ! -f "${ELECTRON_ZIP}" ]]; then
    echo "[3/6] Downloading Electron ${ELECTRON_VERSION} ARM64..."
    curl -fsSL -o "${ELECTRON_ZIP}" "${ELECTRON_BASE}/${ELECTRON_ZIP}"
else
    echo "[3/6] Using cached ${ELECTRON_ZIP}"
fi
curl -fsSL "${ELECTRON_BASE}/SHASUMS256.txt" | grep " \*\?${ELECTRON_ZIP}\$" | sed 's/ \*/  /' | sha256sum -c --quiet \
    || { echo "ERROR: SHA256 mismatch for ${ELECTRON_ZIP}"; rm -f "${ELECTRON_ZIP}"; exit 1; }
echo "      SHA256 verified against Electron's SHASUMS256.txt"

echo "[4/6] Extracting Electron ARM64..."
rm -rf "${ELECTRON_DIR}"
mkdir -p "${ELECTRON_DIR}"
unzip -q "${ELECTRON_ZIP}" -d "${ELECTRON_DIR}/"

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

# Sanity check: no x86-64 ELF files may remain
LEFTOVER=$(find "${APP_DIR}" -type f -exec file {} + | grep -i 'x86-64' || true)
if [[ -n "${LEFTOVER}" ]]; then
    echo "ERROR: x86-64 binaries still present:"
    echo "${LEFTOVER}"
    exit 1
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
chmod 4755 "${APP_DIR}/chrome-sandbox" 2>/dev/null || true

# Build
dpkg-deb --root-owner-group --build "${EXTRACT_DIR}" "${OUTPUT_DEB}"
sha256sum "${OUTPUT_DEB}" > "${OUTPUT_DEB}.sha256"

echo ""
echo "=== Done ==="
echo "Output: ${OUTPUT_DEB}"
echo "SHA256: $(cut -d' ' -f1 "${OUTPUT_DEB}.sha256")"
echo "Install: sudo apt install ./${OUTPUT_DEB}"
