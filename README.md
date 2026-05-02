# Agent Skills Marketplace

Reusable Agent Skills and plugin adapters by [VdustR](https://github.com/VdustR).

> All plugins in this marketplace use the `vp-` prefix (VdustR Plugin).

## Installation

### Codex

```bash
codex plugin marketplace add VdustR/vp-claude-code-marketplace
```

Then open `/plugins` in Codex and install the plugins you want.

When working inside this repository, Codex also sees the repo skills through `.agents/skills`.

### Claude Code

```bash
/plugin marketplace add VdustR/vp-claude-code-marketplace
```

## Available Plugins

> Plugins are listed in alphabetical order.

### vp-checklist-runner

Parse and verify GitHub PR/issue checklists with auto-check and CI integration.

Claude Code:

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

Claude Code:

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

Claude Code:

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

### vp-gitignore-builder

Build and merge .gitignore files using github/gitignore templates.

Claude Code:

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

### vp-guided-focus

Guided focus questioning to align on requirements before planning or complex tasks.

Claude Code:

```bash
/plugin install vp-guided-focus@vdustr
```

Features:
- One-at-a-time structured questioning with options, trade-off analysis, and recommendations
- Dynamic question count (default 10, configurable, auto-adjusts with explanation)
- Proactive trigger on complex/ambiguous tasks (asks permission first)
- Flexible responses: select, combine, free-form, counter-question, skip/defer
- Confidence badges on decisions (confirmed / uncertain / undecided)
- Dependency-aware question ordering — adapts based on previous answers
- Summary with review and handoff to plan or execute

### vp-macos-clean-uninstall

Research-driven macOS app uninstallation with thorough cleanup of all associated data.

Claude Code:

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

### vp-pr-comment-resolver

Automate PR comment review, fix, and resolution workflow.

Claude Code:

```bash
/plugin install vp-pr-comment-resolver@vdustr
```

Features:
- Interactive mode (review each comment) and auto mode (process all automatically)
- Smart author classification — auto-resolves bot threads (including disagreements), preserves human threads for manual review
- Atomic commits per fix with smart grouping for related comments
- Detailed reply format with commit links: `- [hash message](url)`
- Summary report generation after processing all comments
- Human collaboration - asks when uncertain about fixes

### vp-prename

Generate meaningful session names based on overall session theme.

Claude Code:

```bash
/plugin install vp-prename@vdustr
```

Features:
- Names sessions by overall theme and purpose, not just the last action
- Emoji + topic format for scannable session history
- Outputs a platform-specific rename command when the current agent supports one

### vp-retro

Session retrospective — reflect on recent work to discover improvement opportunities through interactive dialogue.

Claude Code:

```bash
/plugin install vp-retro@vdustr
```

Features:
- Open-ended session observation with 15-dimension safety-net checklist
- Interactive deep-dive with parallel subagent research
- Full analysis cycle per finding: research → analyze → design solutions → present options
- Correction root-cause analysis: traces to missing conventions, unclear docs, or skill gaps
- Proactive discovery: codifies good practices before they're forgotten
- Skill ecosystem audit: checks ownership before recommending changes
- Context-aware action planning (direct edit / worktree / PR / issue / .md note)

### vp-skills

Manage agent skills using the npx skills CLI.

Claude Code:

```bash
/plugin install vp-skills@vdustr
```

Features:
- Install skills from any git repository using `npx skills`
- List, search, and discover available skills
- Update all installed skills with one command
- Support for global and project-level skill scopes

### vp-stacked-pr-rebase

Rebase stacked PRs after parent PR is merged, preserving only your commits.

Claude Code:

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

Claude Code:

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

## Development

Each plugin is self-contained: plugin manifests live in `.codex-plugin/plugin.json`, and skill sources live under `plugins/vp-*/skills/`. The repo-root `skills/` directory is an Agent Skills index made of symlinks back to those plugin-local skills. Claude Code compatibility paths are symlinks back to canonical plugin files.

See [AGENTS.md](AGENTS.md) for maintenance rules.

## License

[MIT](https://github.com/VdustR/vp-claude-code-marketplace/blob/main/LICENSE) - Made with 🤖❤️ by [VdustR](https://github.com/VdustR)
