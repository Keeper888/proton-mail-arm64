# Proton Mail for ARM64 Linux

Unofficial repack of the **official Proton Mail desktop app** for **ARM64** (aarch64) Debian/Ubuntu systems.

Proton ships a Linux desktop client, but only for `amd64`. This repo swaps the x64 Electron runtime for ARM64 and rebuilds the `.deb`, so you get the real Proton Mail desktop experience on ARM64 devices — Raspberry Pi, uConsole, ARM laptops, VMs, etc.

## Quick Install

```bash
# Download the pre-built ARM64 package
wget https://github.com/Keeper888/proton-mail-arm64/releases/download/v1.13.4/proton-mail_1.13.4_arm64.deb

# Install
sudo dpkg -i proton-mail_1.13.4_arm64.deb
sudo apt-get install -f   # resolve dependencies
```

Launch **Proton Mail Beta** from your app menu.

## Build It Yourself

```bash
git clone https://github.com/Keeper888/proton-mail-arm64.git
cd proton-mail-arm64
./repack-arm64.sh
sudo dpkg -i proton-mail_1.13.4_arm64.deb
```

## What Gets Replaced

| Component | Source | Why |
|-----------|--------|-----|
| `Proton Mail Beta` binary | Electron v42.8.0 ARM64 | Main executable |
| `chrome-sandbox` | Electron ARM64 | Sandbox helper |
| `libEGL.so`, `libGLESv2.so`, `libffmpeg.so` | Electron ARM64 | Graphics & media |
| `icudtl.dat`, `*.pak`, snapshots | Electron ARM64 | Runtime data |
| `resources/app.asar` | Official .deb | App code (JS, arch-independent) |
| `DEBIAN/control` | Patched | `Architecture: arm64` |

## Verify It’s Really ARM64

```bash
file "/usr/lib/proton-mail/Proton Mail Beta"
# ELF 64-bit LSB pie executable, ARM aarch64, version 1 (SYSV), ...
```

## Notes

- **Unofficial** — Proton does not publish ARM64 Linux builds. Use at your own risk.
- **Auto-updater** may try to fetch amd64 updates. Disable in settings if needed.
- If Proton ever ships official ARM64 builds, this repo becomes unnecessary.

## Credits

Built with [Kimi Code CLI](https://github.com/MoonshotAI/kimi-code) — the AI pair programmer that did the heavy lifting.

## License

- Proton Mail app: [GPL-3.0](https://github.com/ProtonMail/WebClients/blob/main/LICENSE)
- Repack script: MIT
