---
name: localsend
description: >-
  Send and receive files over local network using LocalSend protocol (like AirDrop).
  This skill should be used when the user asks to "send a file", "transfer files
  to my phone", "share files locally", "receive files", "accept files from phone",
  "scan for devices", "find nearby devices", requests "/localsend", or mentions
  wanting to send or receive files over the local network without internet.
  Works with any LocalSend client (mobile app, desktop app, or another Claude Code).
---

# LocalSend

Send and receive files over local network via [LocalSend protocol](https://github.com/localsend/protocol). Compatible with all LocalSend clients (iOS, Android, macOS, Windows, Linux).

Auto-downloads [localsend-cli](https://github.com/0w0mewo/localsend-cli) on first use.

## Commands

| Action | Command |
|--------|---------|
| Setup / install | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/localsend.sh" setup` |
| Scan devices | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/localsend.sh" scan [timeout]` |
| Send file/dir | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/localsend.sh" send <ip> <path> [--pin=PIN]` |
| Start receiving | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/localsend.sh" receive start [save-dir]` |
| Stop receiving | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/localsend.sh" receive stop` |
| Check status | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/localsend.sh" receive status` |

## Workflow: Sending Files

1. Scan the network to discover devices.
2. Identify the target device IP from scan results.
3. Send the file or directory to the target IP.
4. The receiver must accept the transfer (unless they have auto-accept enabled).

If the user provides a target IP directly, skip the scan step.

## Workflow: Receiving Files

1. Start the receive server as a background process (do not wait for it to exit).
2. Tell the user: the server is running and they can send files from their device.
3. The sender's device should discover this machine automatically.
4. Files are saved to `~/.cache/vp-localsend/received/` by default.

### Idle Server Reminder (IMPORTANT)

After starting the receive server, track its state:

- If the user starts working on other tasks, check the server status periodically.
- If the server has been running and the user has not mentioned receiving files or stopping the server, remind them:
  > "The LocalSend receive server is still running. Stop it if you're done receiving files."
- Always check and report status before ending a conversation or switching context.

## Notes

- **First run**: Automatically downloads localsend-cli (~5 MB) to `~/.cache/vp-localsend/`.
- **Network**: Both devices must be on the same local network (WiFi/LAN). Port 53317 must not be blocked by firewall.
- **Receive server**: Runs as a background process. Always stop it when done.
- **PIN**: Use `--pin=PIN` for send if the receiver requires PIN authentication.
- **Platforms**: macOS (arm64/amd64) and Linux (arm64/amd64) are supported.
