---
name: somafm
description: >-
  This skill should be used when the user asks to "play music", "play radio",
  "play SomaFM", "stop music", "stop radio", "list radio channels",
  "change volume", "what's playing", "now playing", "radio status",
  requests "/somafm", or mentions wanting background music, ambient sounds,
  or lo-fi radio while coding. Plays SomaFM internet radio as background
  music during coding sessions.
---

# SomaFM Radio

Play [SomaFM](https://somafm.com/) internet radio as background music during coding sessions.

## When to Use

Invoke this skill when:

- User requests `/somafm` or asks to play music/radio
- User mentions wanting background music, ambient sounds, or lo-fi radio
- User asks to stop music, check what's playing, or change volume
- User wants to browse available radio channels

## Commands

| Action | Command |
|--------|---------|
| Play channel | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/somafm.sh" play [channel] [--volume=N]` |
| Stop playback | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/somafm.sh" stop` |
| Show status | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/somafm.sh" status` |
| List channels | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/somafm.sh" list` |
| Change volume | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/somafm.sh" volume <0-100>` |

## Examples

- **Play default channel**: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/somafm.sh" play` (groovesalad at volume 50)
- **Play specific channel**: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/somafm.sh" play defcon --volume=30`
- **Check now playing**: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/somafm.sh" status`
- **Adjust volume**: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/somafm.sh" volume 70`

## Notes

- **Dependencies**: Requires `mpv`, `curl`, and `jq`. The script checks for missing tools and provides install guidance.
- **Default channel**: `groovesalad` (ambient/chill). Run `list` to browse all channels sorted by listener count.
- **Default volume**: 50 (range: 0-100).
- **Volume control**: Uses mpv IPC socket for seamless changes without interrupting playback.
- **One stream at a time**: Starting a new channel automatically stops the previous one.
