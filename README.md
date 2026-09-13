# Proton Mail for ARM64 Linux

[![Latest release](https://img.shields.io/github/v/release/Keeper888/proton-mail-arm64?label=release)](https://github.com/Keeper888/proton-mail-arm64/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/Keeper888/proton-mail-arm64/total)](https://github.com/Keeper888/proton-mail-arm64/releases)
![Architecture](https://img.shields.io/badge/arch-arm64%20%2F%20aarch64-blue)
[![License: MIT](https://img.shields.io/badge/scripts-MIT-green)](LICENSE)

Unofficial repack of the **official Proton Mail desktop app** for **ARM64** (aarch64) Debian/Ubuntu systems.

Proton only ships its Linux desktop client for `amd64`. This repo swaps the x64 Electron runtime for the matching ARM64 one and rebuilds the `.deb`. You get the real Proton Mail desktop app on ARM64 devices: Raspberry Pi, uConsole, ARM laptops, VMs and more.

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/Keeper888/proton-mail-arm64/main/install.sh | bash
```

The script installs the latest release, checks its SHA256 and resolves dependencies through `apt`.

### Manual install

```bash
wget https://github.com/Keeper888/proton-mail-arm64/releases/download/v1.14.0/proton-mail_1.14.0_arm64.deb
sudo apt install ./proton-mail_1.14.0_arm64.deb
```

Launch **Proton Mail Beta** from your app menu.

### Update

Run the install command again. It always fetches the latest release.

### Uninstall

```bash
sudo apt remove proton-mail
```

## Build it yourself

```bash
git clone https://github.com/Keeper888/proton-mail-arm64.git
cd proton-mail-arm64
./repack-arm64.sh            # latest stable from Proton
./repack-arm64.sh 1.14.0     # or a specific version
```

The build script:

1. Reads Proton's release feed (`version.json`) to find the version and its SHA512.
2. Downloads the official amd64 `.deb` and **checks the SHA512**.
3. Detects the Electron version Proton bundled, then downloads the same ARM64 Electron build and **checks its SHA256** against Electron's `SHASUMS256.txt`.
4. Swaps the binaries and **fails if any x86-64 file is left**.
5. Rebuilds the `.deb` and writes a `.sha256` file.

Build dependencies: `curl unzip dpkg python3 file`.

## What gets replaced

| Component | Source | Why |
|-----------|--------|-----|
| `Proton Mail Beta` binary | Electron ARM64 (same version) | Main executable |
| `chrome-sandbox`, `chrome_crashpad_handler` | Electron ARM64 | Sandbox and crash helpers |
| `libEGL.so`, `libGLESv2.so`, `libffmpeg.so`, `libvulkan.so.1`, SwiftShader | Electron ARM64 | Graphics and media |
| `icudtl.dat`, `*.pak`, snapshots, `locales/` | Electron ARM64 | Runtime data |
| `resources/app.asar` | Official .deb, unchanged | App code (JavaScript, works on any arch) |
| `DEBIAN/control` | Patched | `Architecture: arm64` |

## Verify it's really ARM64

```bash
file "/usr/lib/proton-mail/Proton Mail Beta"
# ELF 64-bit LSB pie executable, ARM aarch64, ...
```

## Releases

| Proton Mail | Electron | Released |
|-------------|----------|----------|
| [1.14.0](https://github.com/Keeper888/proton-mail-arm64/releases/tag/v1.14.0) | 42.9.0 | 2026-09-13 |
| [1.13.4](https://github.com/Keeper888/proton-mail-arm64/releases/tag/v1.13.4) | 42.8.0 | 2026-08-15 |

## Notes

- **Unofficial.** Proton does not publish ARM64 Linux builds and is not involved with this project. Use at your own risk.
- **Auto-updater:** the built-in updater only knows about amd64 builds. Update through this repo instead.
- Tested on a ClockworkPi uConsole (Debian arm64).
- If Proton ships official ARM64 builds, this repo will no longer be needed.

## Credits

Originally built with [Kimi Code CLI](https://github.com/MoonshotAI/kimi-code). Updated with [Claude Code](https://claude.com/claude-code).

## License

- Repack scripts: [MIT](LICENSE)
- Proton Mail app: [GPL-3.0](https://github.com/ProtonMail/WebClients/blob/main/LICENSE), © Proton AG
- Electron: MIT, © Electron contributors
