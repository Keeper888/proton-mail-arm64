#!/bin/bash
# One-line installer for Proton Mail on ARM64 Linux (Debian/Ubuntu/Raspberry Pi OS)
#   curl -fsSL https://raw.githubusercontent.com/Keeper888/proton-mail-arm64/main/install.sh | bash
# Installs the latest release from github.com/Keeper888/proton-mail-arm64

set -euo pipefail

REPO="Keeper888/proton-mail-arm64"

ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)
if [[ "${ARCH}" != "arm64" && "${ARCH}" != "aarch64" ]]; then
    echo "ERROR: this package is for ARM64 only (detected: ${ARCH})."
    echo "On amd64, use the official build: https://proton.me/mail/download"
    exit 1
fi

echo "Finding latest release..."
TAG=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep -m1 '"tag_name"' | cut -d'"' -f4)
VERSION="${TAG#v}"
DEB="proton-mail_${VERSION}_arm64.deb"
BASE="https://github.com/${REPO}/releases/download/${TAG}"

TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

echo "Downloading Proton Mail ${VERSION} (arm64)..."
curl -fL --progress-bar -o "${TMP}/${DEB}" "${BASE}/${DEB}"
if curl -fsSL -o "${TMP}/${DEB}.sha256" "${BASE}/${DEB}.sha256"; then
    (cd "${TMP}" && sha256sum -c --quiet "${DEB}.sha256") || { echo "ERROR: checksum mismatch"; exit 1; }
    echo "Checksum OK"
fi

echo "Installing (sudo password may be requested)..."
chmod 644 "${TMP}/${DEB}"
sudo apt-get install -y "${TMP}/${DEB}"

echo ""
echo "Done. Launch 'Proton Mail Beta' from your app menu."
