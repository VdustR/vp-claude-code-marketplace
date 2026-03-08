# Claude Code Marketplace

Claude Code plugins by [VdustR](https://github.com/VdustR).

> All plugins in this marketplace use the `vp-` prefix (VdustR Plugin).

## Installation

```bash
/plugin marketplace add VdustR/vp-claude-code-marketplace
```

## Available Plugins

> Plugins are listed in alphabetical order.

### vp-checklist-runner

Parse and verify GitHub PR/issue checklists with auto-check and CI integration.

```bash
/plugin install vp-checklist-runner@vdustr
```

Features:
- 5-phase workflow: source resolution, classification, verification, checkbox update, summary report
- Auto-classifies checklist items into Auto / CI / Shell / Scan / Human categories
- CI-first verification — checks CI status before running tests locally
- Ownership-aware updates — respects GitHub permissions, defaults to comment mode for others' posts
- Race condition prevention via `updated_at` timestamp comparison
- Confidence-based automation — only pauses for uncertain items
- Scan subagents for semantic checks (secrets, docs, changelog) with user confirmation

### vp-cspell

Handle cspell unknown word warnings with prioritized decision tree and config bootstrapping.

```bash
/plugin install vp-cspell@vdustr
```

Features:
- Prioritized decision tree: adjust text > project dictionary > inline directives
- Smart inline directive selection (cspell:words vs cspell:ignore vs cspell:disable)
- Interactive config bootstrapping via `cspell init` with guided Q&A
- Runtime documentation via Context7 — no stale reference files

### vp-deps-shift

Dependency upgrade and library migration with breaking change detection and test-first verification.

```bash
/plugin install vp-deps-shift@vdustr
```

**Skills included:**
- **deps-upgrade** — Version upgrades with breaking change detection, deps bot PR handling
- **deps-migrate** — Library replacement and API pattern migration (e.g., forwardRef removal)

Features:
- Test-first verification in /tmp before batch execution
- Context7 + changelog parallel documentation lookup
- Official codemod detection and compat layer support
- 3-pass subagent review loop (direct, best practice, critical think)
- Multi-ecosystem support (npm, pnpm, yarn, bun, cargo, pip, go, bundler, composer)
- Deps bot PR handling (dependabot, renovate)
- Repo convention compliance (changesets, conventional commits, CI checks)

### vp-gmaps-list

Extract all places from a Google Maps saved list via internal API.

```bash
/plugin install vp-gmaps-list@vdustr
```

Features:
- Single API call extraction — bypasses UI scroll-based rendering to get all items at once
- Full place data: name, address, coordinates, Google Place ID, user notes
- Supports short URLs (`maps.app.goo.gl/...`) and full URLs
- Output as summary table, JSON, or CSV
- Requires [agent-browser](https://github.com/anthropics/claude-code/tree/main/.claude/skills/agent-browser) skill

### vp-gitignore-builder

Build and merge .gitignore files using github/gitignore templates.

```bash
/plugin install vp-gitignore-builder@vdustr
```

Features:
- Smart project detection (Node, Python, Rust, Go, etc.)
- Live fetch from [github/gitignore](https://github.com/github/gitignore) for latest templates
- Intelligent merge with existing .gitignore files
- EOL conflict detection and resolution
- Auto-suggest `*.local` and `*.local.*` patterns
- Support for both project-level and global gitignore

### vp-localsend

Send and receive files over local network using [LocalSend](https://localsend.org/) protocol (like AirDrop).

```bash
/plugin install vp-localsend@vdustr
```

Features:
- Scan for nearby LocalSend devices on local network
- Send files and directories to any LocalSend client (phone, tablet, PC)
- Receive files from other devices with background server
- Auto-downloads [localsend-cli](https://github.com/0w0mewo/localsend-cli) on first use
- Idle server reminder to prevent forgotten background processes
- Compatible with all LocalSend apps (iOS, Android, macOS, Windows, Linux)

### vp-macos-clean-uninstall

Research-driven macOS app uninstallation with thorough cleanup of all associated data.

```bash
/plugin install vp-macos-clean-uninstall@vdustr
```

Features:
- 7-phase workflow: detect install method → research → scan → subagent review → plan → execute → verify
- Detects Homebrew, DMG, PKG, Mac App Store, CLI tools (npm/pip3/cargo), and manual installs
- Mandatory web research with official vendor docs prioritized over community sources
- Deep associated data scan across ~/Library, /Library, ~/.config, ~/.local, and dotfiles
- Categorized removal plan with file sizes and recommendations
- Defaults to clean removal — recommends removing all residual data
- Always confirms before deletion — flags irreplaceable user data separately

### vp-nyan-mode

Cat persona with 'nyan~' verbal tic, emoji support, and language matching.

```bash
/plugin install vp-nyan-mode@vdustr
```

Features:
- Adds 'nyan~' verbal tic to responses
- Enables emoji usage
- Matches user's language preference

### vp-pr-comment-resolver

Automate PR comment review, fix, and resolution workflow.

```bash
/plugin install vp-pr-comment-resolver@vdustr
```

Features:
- Interactive mode (review each comment) and auto mode (process all automatically)
- Atomic commits per fix with smart grouping for related comments
- Detailed reply format with commit links: `- [hash message](url)`
- Summary report generation after processing all comments
- Human collaboration - asks when uncertain about fixes

### vp-review-loop

Iterative multi-pass subagent review loop with confidence scoring for code and plans.

```bash
/plugin install vp-review-loop@vdustr
```

**Skills included:**
- **review-loop** — Multi-pass code review (Direct, Best Practice, Critical Think) with iterative fix cycles
- **plan-review** — Plan optimization with confidence index scoring and pros/cons analysis

Features:
- 3 built-in passes: Direct (correctness), Best Practice (quality), Critical Think (risk)
- Context-aware suggested passes: Testability, Accessibility, API Surface, Performance, i18n, Concurrency (code); Incremental Delivery, Stakeholder Impact, Maintenance Burden, Team Coordination (plans)
- Iterative fix-review loop with stall detection and ping-pong mitigation
- Generalized confidence index with 5 factors, floor rule, and boost options
- Structured pros/cons analysis for plan decisions
- Extensible: custom subagent passes + manual external AI review support

### vp-skills

Manage agent skills using the npx skills CLI.

```bash
/plugin install vp-skills@vdustr
```

Features:
- Install skills from any git repository using `npx skills`
- List, search, and discover available skills
- Update all installed skills with one command
- Support for global and project-level skill scopes

### vp-somafm

Play SomaFM internet radio as background music during coding sessions.

```bash
/plugin install vp-somafm@vdustr
```

Features:
- Stream any SomaFM channel with one command (default: groovesalad)
- Browse channels with live listener counts from SomaFM API
- Now-playing track info and playback status
- Seamless volume control via mpv IPC socket
- Auto-detect missing dependencies with install guidance

### vp-stacked-pr-rebase

Rebase stacked PRs after parent PR is merged, preserving only your commits.

```bash
/plugin install vp-stacked-pr-rebase@vdustr
```

Features:
- Smart parent PR detection via commit analysis
- Handles all merge types (regular, squash, rebase)
- Automatic commit classification (parent vs your own)
- Simple conflict auto-resolution, asks for complex conflicts
- Safe operations with backup branches and `--force-with-lease`
- Detailed summary report with before/after visualization

### vp-typescript-best-practices

TypeScript coding guidelines with dos and don'ts for type design and patterns.

```bash
/plugin install vp-typescript-best-practices@vdustr
```

Features:
- Type-first design with namespace pattern for organizing types
- Clear DO/DON'T tables for interface vs type, any usage, function declarations
- Naming conventions (PascalCase, `T` prefix for generics, `Id` not `ID`)
- Type extraction patterns (prefer extracting over redefining)
- Generic const pattern for strict literal inference
- Type testing guidelines with `*.test-d.ts`
- Environment setup with strictest tsconfig and ts-reset

### vp-wenyan-mode

Classical Chinese (文言文) writing style with concise, elegant expressions.

```bash
/plugin install vp-wenyan-mode@vdustr
```

Features:
- Always-active classical Chinese writing style
- Concise expressions (言簡意賅)
- Technical terms preserved (function, API, commit, etc.)
- Minimal use of classical particles (之乎者也)

## Development

This marketplace is developed using the [plugin-dev](https://github.com/anthropics/claude-code/tree/main/.claude/plugins/plugin-dev) plugin.

## License

[MIT](https://github.com/VdustR/vp-claude-code-marketplace/blob/main/LICENSE) - Made with 🤖❤️ by [VdustR](https://github.com/VdustR)
