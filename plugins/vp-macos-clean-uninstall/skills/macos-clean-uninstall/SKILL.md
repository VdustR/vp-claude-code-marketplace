---
name: macos-clean-uninstall
description: >-
  Cleanly uninstall applications on macOS with thorough research and cleanup.
  Use when the user asks to "uninstall", "remove", "delete", or "clean up"
  an application, program, CLI tool, or package on macOS.
  Also use when the user wants to check what residual data an app has left behind,
  or asks to "check leftover files" for an app.
---

# Clean Uninstall (macOS)

Research-driven workflow for completely removing applications and all associated data from macOS.

## Quick Start

> Uninstall Docker from my Mac

> Remove Slack and all its data

> What files did Zoom leave behind?

> Clean uninstall 1Password

## When to Use

- User asks to uninstall, remove, or delete a macOS application
- User wants to check for residual data left by an app
- User wants to free disk space by cleaning up after a removed app

**When NOT to use:**
- Linux or Windows uninstalls — this skill is macOS-only
- Removing system-bundled apps (Safari, Mail, Finder) — these are SIP-protected
- Clearing browser data or cookies only — not an app uninstall
- Removing macOS system updates

## Workflow

Execute these phases in order. Never skip the research and review phases.

**Prerequisite**: If the app name cannot be determined unambiguously, ask the user to clarify. Never substitute an empty or whitespace-only string into any command.

Define these variables once and use throughout:
- `APP_NAME` — CLI/short name (e.g., `docker`, `slack`)
- `APP_DISPLAY` — display name for `.app` bundle (e.g., `Docker`, `Slack`)
- `BUNDLE_ID` — bundle identifier (e.g., `com.docker.docker`)

### Phase 1: Identify Installation Method

Determine how the app was installed — this dictates the correct removal procedure.

**Run all detection commands in parallel:**

```bash
# Homebrew
brew list --formula | grep -i "${APP_NAME}"
brew list --cask | grep -i "${APP_NAME}"

# App bundle
ls "/Applications/${APP_DISPLAY}.app" ~/Applications/*"${APP_NAME}"*.app 2>/dev/null

# Bundle ID (use mdls first; osascript may launch the app — use only as fallback)
mdls -name kMDItemCFBundleIdentifier "/Applications/${APP_DISPLAY}.app" 2>/dev/null \
  || mdls -name kMDItemCFBundleIdentifier ~/Applications/*"${APP_NAME}"*.app 2>/dev/null

# PKG receipt
pkgutil --pkgs | grep -i "${APP_NAME}"

# Mac App Store
ls "/Applications/${APP_DISPLAY}.app/Contents/_MASReceipt" 2>/dev/null

# Bundled uninstaller
find "/Applications/${APP_DISPLAY}.app/Contents" -maxdepth 3 \
  \( -iname "*uninstall*" -o -iname "*remove*" \) 2>/dev/null
ls "/Applications/"*"${APP_NAME}"*[Uu]ninstall* 2>/dev/null

# Symlink check
RESOLVED=$(readlink "$(command -v "${APP_NAME}")" 2>/dev/null)
[ -L "$(command -v "${APP_NAME}")" ] && echo "Symlink: $(command -v "${APP_NAME}") → ${RESOLVED}"
```

**If not found above**, check CLI package managers:

```bash
command -v "${APP_NAME}" 2>/dev/null
npm list -g "${APP_NAME}" 2>/dev/null
pip3 show "${APP_NAME}" 2>/dev/null
command -v cargo >/dev/null && cargo install --list 2>/dev/null | grep -i "${APP_NAME}"
```

**Symlink handling**: If the target is a symlink, determine the relationship and ask the user:

| Scenario | Action |
|----------|--------|
| Symlink to a package manager binary (e.g., `npx` → npm) | Only remove the symlink |
| Symlink to another app (e.g., `code` → VS Code) | Ask: remove alias only, or uninstall parent app + all aliases? |
| Multiple symlinks to same app | List all; if uninstalling, remove all |

**Bundled uninstaller**: If found, it takes priority over manual removal in Phase 6. Only use uninstallers from within the installed app bundle or the vendor's verified domain.

### Phase 2: Research Official Uninstall Method

**Mandatory**: Search the web for the correct uninstall procedure.

1. **First search**: `"<app name>" official uninstall macOS site:<vendor-domain>`
2. **Second search**: `"<app name>" uninstall macOS`
3. **Evaluate sources** — prioritize: official vendor docs > vendor GitHub > Apple Support > community forums
4. **Reject** blog spam, SEO-farm "cleaner" app promotions, and unverified guides

**Critical**: Some apps have dedicated uninstallers or CLI commands (e.g., `docker`, `1Password`, `Karabiner-Elements`, `FUSE`). Missing these can leave kernel extensions, daemons, or system modifications behind.

### Phase 3: Scan Associated Data

**If the app name is ambiguous** (shorter than 4 characters or a common word like `go`, `pro`, `mail`, `code`, `sync`, `file`, `app`), use bundle ID only:

```bash
find ~/Library /Library -maxdepth 3 -iname "*${BUNDLE_ID}*" 2>/dev/null
find ~/.config ~/.local -maxdepth 2 -iname "*${BUNDLE_ID}*" 2>/dev/null
```

**Otherwise**, scan with both app name and bundle ID:

```bash
echo "=== User Library ==="
find ~/Library -maxdepth 3 \( -iname "*${APP_NAME}*" -o -iname "*${BUNDLE_ID}*" \) 2>/dev/null

echo "=== System Library ==="
find /Library -maxdepth 3 \( -iname "*${APP_NAME}*" -o -iname "*${BUNDLE_ID}*" \) 2>/dev/null

echo "=== XDG Config ==="
find ~/.config ~/.local -maxdepth 2 \( -iname "*${APP_NAME}*" -o -iname "*${BUNDLE_ID}*" \) 2>/dev/null

echo "=== Dotfiles ==="
ls -d ~/."${APP_NAME}" ~/."${APP_NAME}"rc 2>/dev/null
```

In both cases, require manual verification of every name-based match before including in the removal plan.

### Phase 4: Subagent Review of Removal Plan

**Mandatory**: Before presenting the plan to the user, launch a subagent to review the entire removal plan.

Subagent prompt must include: app name, bundle ID, installation method, full file list, uninstall steps in order, and research sources.

**Subagent review checklist:**
- [ ] Uninstall steps match official documentation
- [ ] No vendor-provided uninstaller is being skipped
- [ ] PKG apps: `pkgutil --files <pkg-id>` output reviewed for system-level files
- [ ] No paths under `/System/`, `/usr/bin/`, `/usr/lib/`, `/bin/`, `/sbin/`, `/etc/`, `/var/`, `/tmp/`, `/private/`, or `~/` alone. Paths under `/usr/local/lib/`, `/usr/local/share/`, `/opt/homebrew/lib/`, `/opt/homebrew/share/` require explicit user confirmation
- [ ] No overly broad glob patterns; ambiguous names (short or common words) use bundle ID matching only
- [ ] Launch agents/daemons identified and will be unloaded before deletion
- [ ] Kernel extensions or system extensions identified if applicable
- [ ] PKG receipt files list reviewed — no shared components being removed
- [ ] Homebrew apps: `brew uses --installed <name>` checked for reverse dependencies
- [ ] Execution order is safe (check/stop processes → unload services → remove app → remove data → forget receipts)
- [ ] All paths are absolute and explicitly listed
- [ ] Each scan match cross-referenced against bundle ID, not just app name

If the subagent raises any concern, resolve it before proceeding.

### Phase 5: Present Removal Plan

Present a categorized table to the user:

| Category | Path | Size | Action |
|----------|------|------|--------|
| App binary | `/Applications/Foo.app` | 150 MB | Remove |
| Preferences | `~/Library/Preferences/com.foo.plist` | 4 KB | Trash |
| Cache | `~/Library/Caches/com.foo` | 23 MB | Remove |

**Default recommendation: remove everything** (clean uninstall). Flag items containing potentially irreplaceable user data (configuration, databases, project files) and ask explicitly.

**Recovery approach**: Move user data directories (Application Support, Preferences) to Trash instead of `rm -rf`. Use `rm -rf` only for caches and temporary files. To avoid name collisions in Trash, append a timestamp: `mv "<path>" ~/.Trash/"$(basename "<path>")_$(date +%s)"`.

Warn about: login items, browser extensions, privacy permissions, kernel extensions requiring reboot.

### Phase 6: Execute with Confirmation

1. **Ask for confirmation** before any deletion
2. **Check for running processes** before removal:
   ```bash
   pgrep -il "${APP_NAME}"
   ```
   If processes are found, present options to the user:
   | Option | Action |
   |--------|--------|
   | Quit gracefully | `osascript -e "tell application \"${APP_DISPLAY}\" to quit"` then recheck after 5s (max 3 retries, then offer force kill) |
   | Force kill | `killall "${APP_DISPLAY}"` (warn: may lose unsaved data) |
   | Remove auto-launch first, reboot later | Unload launch agents/daemons (step 3) + remove login items, then ask user to reboot and re-run removal |

   **Note:** If a launch agent has `KeepAlive` enabled, the process will respawn after quit/kill. In that case, fall back to the "Remove auto-launch first" option.
3. **Unload launch agents/daemons**:
   ```bash
   LABEL=$(/usr/libexec/PlistBuddy -c "Print :Label" "<plist-path>")
   # User agent (~/Library/LaunchAgents/)
   launchctl bootout "gui/$(id -u)/${LABEL}"
   launchctl print "gui/$(id -u)/${LABEL}" 2>&1 | grep -q "Could not find" && echo "User agent unloaded"
   # System daemon (/Library/LaunchDaemons/) — requires sudo
   sudo launchctl bootout "system/${LABEL}"
   sudo launchctl print "system/${LABEL}" 2>&1 | grep -q "Could not find" && echo "System daemon unloaded"
   ```
4. **Use Homebrew** if applicable — use the **exact cask/formula token** from Phase 1 `brew list` output (not the user-provided name):
   - Cask: `brew uninstall --zap --cask "<exact-token>"` (`--zap` removes all associated files)
   - Formula: `brew uninstall "<exact-token>"`
   If multiple tokens matched `grep -i` in Phase 1, list all matches and ask the user to select the correct one
5. **Use vendor uninstaller** if one was found in Phase 1
6. **Remove associated data** — Trash for user data, `rm -rf` for caches. Explicit paths only
7. **Forget PKG receipts** — **ALWAYS after removing files** (once forgotten, file list is unrecoverable): `sudo pkgutil --forget <pkg-id>`

### Phase 7: Post-Removal Verification

**Targeted verification** — check only the specific paths from the removal plan:

```bash
# Check each removed path still exists
ls -d <path1> <path2> ... 2>/dev/null

# Check for residual processes
pgrep -il "${APP_NAME}"

# Check for residual login items
osascript -e 'tell application "System Events" to get the name of every login item'
```

**Follow-up reminder checklist** — inform the user about any applicable items:

| Condition | Reminder |
|-----------|----------|
| Kernel extension, system extension, or system daemon removed | Reboot required/recommended |
| App had privacy permissions (Accessibility, Full Disk Access, etc.) | Remove in System Settings → Privacy & Security |
| App had Login Items entries | Remove in System Settings → General → Login Items |
| App installed browser extensions | Remove from browser(s) |
| App used network configuration (VPN, proxy, DNS) | Verify System Settings → Network |
| App installed shell integrations (PATH, completions, aliases) | Check `~/.zshrc`, `~/.bashrc`, `~/.zprofile`, `/etc/paths.d/` |
| Homebrew dependencies no longer needed | Suggest `brew autoremove` |
| App stored data in iCloud / cloud sync | Data may still exist in cloud |
| App modified `/etc/hosts`, `/etc/shells`, or similar | Verify restored |

Always present applicable reminders — err on the side of informing.
