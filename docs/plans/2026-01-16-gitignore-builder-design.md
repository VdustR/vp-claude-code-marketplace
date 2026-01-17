# Gitignore Builder Plugin Design

## Overview

A Claude Code plugin that builds and merges `.gitignore` files using templates from [github/gitignore](https://github.com/github/gitignore) with smart project detection.

## Features

| Feature | Description |
|---------|-------------|
| Smart detection | Project-level: indicator files / Global: OS + IDE |
| Live fetch | Real-time fetch from github/gitignore for latest templates |
| Merge with diff | Smart merge with existing files, preview before write |
| EOL handling | Detect conflicts, ask user for unified format |
| Location guard | Warn when requesting global gitignore inside a repo |
| Auto-trigger | Suggest on new projects, related discussions, suspicious files |
| *.local suggestion | Always recommend `*.local` and `*.local.*` patterns |

## Plugin Structure

```
plugins/gitignore-builder/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   └── gitignore-builder/
│       └── SKILL.md
└── scripts/
    └── merge-gitignore.sh
```

## Workflow

```
User trigger or auto-detect
        ↓
Determine target location (repo root / ~)
        ↓
Scan project indicators → recommend templates
        ↓
Live fetch from github/gitignore
        ↓
Run merge-gitignore.sh to combine
        ↓
If existing .gitignore → merge + show diff
        ↓
User confirms → write file
```

## Detection Logic

### Project-level (Basic Detection)

| Indicator File | Template |
|----------------|----------|
| `package.json` | Node.gitignore |
| `requirements.txt`, `pyproject.toml`, `setup.py`, `Pipfile` | Python.gitignore |
| `Cargo.toml` | Rust.gitignore |
| `go.mod` | Go.gitignore |
| `composer.json` | Composer.gitignore |
| `Gemfile` | Ruby.gitignore |
| `pom.xml` | Maven.gitignore |
| `build.gradle`, `build.gradle.kts` | Gradle.gitignore |
| `*.swift`, `Package.swift` | Swift.gitignore |
| `*.csproj`, `*.sln` | VisualStudio.gitignore |

### Global (Environment-Aware)

| Detection Method | Template (from Global/) |
|------------------|-------------------------|
| `uname` = Darwin | macOS.gitignore |
| `uname` = Linux | Linux.gitignore |
| Windows environment | Windows.gitignore |
| `.vscode/` exists or `code` available | VisualStudioCode.gitignore |
| `.idea/` exists | JetBrains.gitignore |
| `vim` or `nvim` available | Vim.gitignore |
| `emacs` available | Emacs.gitignore |

## Location Rules

| Situation | Action |
|-----------|--------|
| Inside repo, project-level | Use repo root |
| Inside repo, global requested | Warn: recommend `~/.gitignore`, ask confirmation |
| Not in repo | Suggest global at `~/.gitignore` |
| Target has existing `.gitignore` | Read, merge, show diff preview |

## Merge Strategy

**Order (later overrides earlier):**

1. Existing `.gitignore` content (preserved at top)
2. Language/framework templates
3. Global templates (OS, IDE) - only for global gitignore
4. Recommended additions (`*.local`, `*.local.*`)

**Rules:**
- Keep duplicates (preserve source integrity)
- Preserve negation (`!`) rules in original position
- Mark user-custom content separately

## EOL Handling

When EOL inconsistency detected:
1. Report all detected EOL types
2. Ask user to choose: LF (recommended), CRLF, or keep as-is
3. Convert after confirmation

## Script Usage

```bash
# Fetch and merge templates
./scripts/merge-gitignore.sh Node Python Global/macOS

# Output format includes:
# - Source attribution comments
# - Full original template content
# - Recommended *.local patterns
```

## Auto-trigger Scenarios

1. **New project**: `git init` or fresh clone without `.gitignore`
2. **Discussion**: User mentions gitignore, ignoring files
3. **Suspicious files**: `git status` shows `node_modules/`, `.env`, `__pycache__/`
