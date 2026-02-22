---
name: qrcp
description: >-
  Transfer files over Wi-Fi by scanning a QR code from the terminal using qrcp.
  This skill should be used when the user mentions "qrcp", "QR code file transfer",
  "send file via QR", "share file with QR code", or requests "/qrcp". Requires
  explicit mention of QR code or qrcp — for general local network file transfer
  without QR, use vp-localsend instead.
---

# qrcp

Transfer files over Wi-Fi by scanning a QR code using [qrcp](https://github.com/claudiodangelis/qrcp). The receiver only needs a browser — no app installation required.

## IMPORTANT: Interactive Execution

Do NOT run qrcp via Bash tool. qrcp is an interactive foreground command that displays a QR code in the terminal and waits for the transfer to complete. The QR code must be visible in the user's own terminal for scanning. Always provide the command for the user to copy and run themselves.

## Availability Check

Run `command -v qrcp` to check if qrcp is installed.

**If not installed**, inform the user and point them to the installation guide:

> qrcp is not installed. See [qrcp installation instructions](https://github.com/claudiodangelis/qrcp#installation) for setup on macOS, Linux, and Windows (Homebrew, Go, Chocolatey, Scoop, AUR, and more).

If `command -v` returns empty but the user believes qrcp is installed, ask them to verify with `qrcp --version` in their own terminal — the PATH in Claude's shell environment may differ.

Do not attempt to install qrcp automatically.

## Usage

Refer to the [qrcp README](https://github.com/claudiodangelis/qrcp#usage) for full and up-to-date usage instructions. The basic workflow:

- **Send** (computer to phone): `qrcp <file-or-directory>` — displays a QR code; phone scans it and downloads via browser
- **Receive** (phone to computer): `qrcp receive --output=<dir>` — displays a QR code; phone scans it and uploads via browser. Use `$TMPDIR` (or the session's temporary directory if one exists) as the output directory to avoid cluttering the home folder. Tell the user where files will be saved.

## Notes

- Both devices must be on the same local network (Wi-Fi or Ethernet). Networks with AP isolation (common in corporate/public Wi-Fi) will block the connection.
- The QR code is printed directly in the terminal — the user scans it with their phone camera or a QR reader app.
- No app is needed on the mobile device, just a browser.
- If the QR code URL is unreachable from the phone, qrcp may have selected the wrong network interface. See [qrcp configuration](https://github.com/claudiodangelis/qrcp#configuration) for the `--interface` flag and other options.
