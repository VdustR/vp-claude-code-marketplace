# Claude Code Marketplace - Project Guidelines

## Plugin Naming Convention

All plugins in this marketplace use the `vp-` prefix (VdustR Plugin).

Example: `vp-add-skill`, `vp-nyan-mode`, `vp-gitignore-builder`

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

## Quality Standards

### Plugin Naming

- **Always use `vp-` prefix**: `vp-my-plugin-name`
- Use kebab-case after the prefix
- Be descriptive but concise
- Avoid generic names like `utils` or `helpers`

### SKILL.md Requirements

1. **Frontmatter** (required):
   ```yaml
   ---
   name: skill-name
   description: One-line description for when to use this skill
   ---
   ```

2. **Sections** (recommended):
   - `# Title` - Clear skill name
   - `## When to Use` - Trigger conditions
   - `## Usage` - Commands and examples
   - `## Notes` - Edge cases, limitations

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

## Checklist Before Commit

- [ ] Plugin name has `vp-` prefix
- [ ] `plugin.json` has all required fields
- [ ] SKILL.md has valid frontmatter
- [ ] Plugin registered in `marketplace.json`
- [ ] Version updated if modifying existing plugin
- [ ] No sensitive data or credentials
- [ ] All paths are relative and correct
- [ ] README.md updated if adding/modifying plugins

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
