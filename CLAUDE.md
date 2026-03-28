# Claude Code Marketplace - Project Guidelines

## Development

This repository uses the `plugin-dev` plugin for development and maintenance. The `.claude/settings.json` file includes this plugin intentionally.

## Plugin Naming Convention

All plugins in this marketplace use the `vp-` prefix (VdustR Plugin).

Example: `vp-gitignore-builder`, `vp-nyan-mode`, `vp-pr-comment-resolver`, `vp-skills`, `vp-typescript-best-practices`, `vp-wenyan-mode`

## Project Structure

```
claude-code-marketplace/
├── .claude-plugin/
│   └── marketplace.json       # Marketplace registry (lists all plugins)
├── plugins/
│   └── vp-<plugin-name>/
│       ├── .claude-plugin/
│       │   └── plugin.json    # Plugin metadata
│       └── skills/
│           └── <skill-name>/
│               └── SKILL.md   # Skill definition
├── templates/                 # Templates for new plugins/skills
└── CLAUDE.md                  # This file
```

## Shared Metadata (Copy for New Plugins)

All plugins in this marketplace share these values:

```json
{
  "author": {
    "name": "VdustR",
    "url": "https://github.com/VdustR"
  },
  "homepage": "https://github.com/VdustR/vp-claude-code-marketplace",
  "repository": "https://github.com/VdustR/vp-claude-code-marketplace",
  "license": "MIT"
}
```

## Creating a New Plugin

### 1. Create Plugin Directory

```bash
mkdir -p plugins/vp-<plugin-name>/.claude-plugin
mkdir -p plugins/vp-<plugin-name>/skills/<skill-name>
```

### 2. Copy and Edit Templates

```bash
cp templates/plugin.json plugins/vp-<plugin-name>/.claude-plugin/plugin.json
cp templates/SKILL.md plugins/vp-<plugin-name>/skills/<skill-name>/SKILL.md
```

### 3. Register in Marketplace

Add entry to `.claude-plugin/marketplace.json`:

```json
{
  "name": "vp-<plugin-name>",
  "source": "./plugins/vp-<plugin-name>",
  "description": "<brief description>",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"]
}
```

## Plugin Development Workflow

Proven end-to-end flow for developing new plugins:

1. **Research** — Survey existing community plugins and prior art
2. **Brainstorm** — Explore ideas, identify skill boundaries and user triggers
3. **Guided focus** — Align on requirements through structured questioning
4. **Plan** — Write an implementation plan before touching code
5. **Worktree** — Create a git worktree for isolated development
6. **Implement** — Build the plugin following Quality Standards below
7. **Review** — Subagent code review for quality and consistency
8. **Commit** — Follow Git Conventions; verify Plugin Change Checklist
9. **PR** — Open pull request with description and test plan
10. **Merge** — Merge and clean up the worktree

Not every plugin needs all steps — lightweight fixes can skip research/brainstorm. Use judgment.

## Quality Standards

### Design Philosophy

Keep skills flexible — describe intent and guidance, not rigid step-by-step procedures. Trust the AI to adapt to the actual conversation. A well-written skill defines *what* to achieve and *why*, then lets the model determine *how* based on context.

### Plugin Naming

- **Always use `vp-` prefix**: `vp-my-plugin-name`
- Use kebab-case after the prefix
- Be descriptive but concise
- Avoid generic names like `utils` or `helpers`

### Plugin Ordering

- **All plugin lists MUST be sorted alphabetically by name**
- This applies to:
  - `marketplace.json` plugins array
  - `README.md` Available Plugins section
  - Any other documentation listing plugins

### SKILL.md Requirements

1. **Frontmatter** (required):
   ```yaml
   ---
   name: skill-name
   description: >-
     Brief description of what the skill does.
     Use when <trigger phrase 1>, <trigger phrase 2>, <trigger phrase 3>,
     or when <context condition>.
     Boundary: <when NOT to use this skill>.
   ---
   ```

   Existing plugins are not required to retroactively update their frontmatter. The multi-line format is the standard for new plugins.

   - `name`: Must match the skill directory name
   - `description`: Multi-line with `>-` block scalar. Include:
     - What the skill does (first sentence)
     - Trigger phrases: natural language patterns users might say (e.g., "review this code", "deep review")
     - Context conditions: when Claude should proactively suggest it
     - Boundary: when NOT to use (to avoid false triggers)

2. **Body sections** (recommended order):
   - `# Title` — Clear skill name
   - Intro paragraph — One-liner summary of the skill
   - `## Quick Start` — Example invocations (natural language, not commands)
   - `## When to Use` — Bullet list of trigger conditions
   - `## Workflow` — Numbered phases with details
   - `## Guidelines` — DO / DON'T lists
   - `## Error Handling` — Table of error → action pairs
   - `## Reference Files` — Links to `references/` files (if any)
   - `## Notes` — Edge cases, limitations

   Not all sections are needed for every skill. Use what's appropriate for the complexity.

### plugin.json Requirements

| Field | Required | Notes |
|-------|----------|-------|
| `name` | Yes | Must match directory name (with `vp-` prefix) |
| `version` | Yes | Semantic versioning (x.y.z) |
| `description` | Yes | One sentence, no period |
| `author` | Yes | Use shared metadata |
| `license` | Yes | MIT |
| `skills` | If applicable | Path to skills directory |

### Version Bumping

- **Patch (0.0.x)**: Bug fixes, typo corrections
- **Minor (0.x.0)**: New features, new skills
- **Major (x.0.0)**: Breaking changes

## Code Style

### Markdown

- Use ATX-style headers (`#`, `##`, `###`)
- One blank line between sections
- Code blocks with language identifiers
- Tables for structured data

### JSON

- 2-space indentation
- No trailing commas
- Keys in logical order: name → version → description → author → ...

### README.md Plugin Entry Format

Each plugin entry in `README.md` follows this structure:

```markdown
### vp-<plugin-name>

<Description sentence from plugin.json, with period.>

\`\`\`bash
/plugin install vp-<plugin-name>@vdustr
\`\`\`

Features:
- Feature 1
- Feature 2
```

For plugins with multiple skills, add a skills section before features:

```markdown
**Skills included:**
- **skill-name-1** — One-line description
- **skill-name-2** — One-line description

Features:
- Feature 1
```

## Plugin Change Checklist

**IMPORTANT:** When any plugin is added, modified, or deleted, ALWAYS verify:

1. **`marketplace.json`** - Plugin registry is updated
2. **`README.md`** - Plugin documentation is updated

This applies to ALL plugin changes including:
- New plugin creation
- Plugin feature updates
- Plugin removal
- Skill additions/modifications

## Checklist Before Commit

- [ ] Plugin name has `vp-` prefix
- [ ] `plugin.json` has all required fields
- [ ] SKILL.md has valid frontmatter
- [ ] Plugin registered in `marketplace.json`
- [ ] **Plugins sorted alphabetically** in `marketplace.json` and `README.md`
- [ ] Version updated if modifying existing plugin
- [ ] No sensitive data or credentials
- [ ] All paths are relative and correct
- [ ] **README.md updated** (required for any plugin change)
- [ ] **marketplace.json updated** (required for any plugin change)

## Git Conventions

### Commit Messages

```
<type>: <description>

Types:
- feat: New plugin or skill
- fix: Bug fix
- docs: Documentation only
- refactor: Code restructuring
- chore: Maintenance tasks
```

### Branch Naming

- `feat/vp-<plugin-name>` - New plugin development
- `fix/<issue>` - Bug fixes
- `docs/<topic>` - Documentation updates
