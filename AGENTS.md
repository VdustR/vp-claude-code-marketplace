# Agent Skills Marketplace - Archived Repository Guidelines

## Status

This repository is deprecated and archived. It is no longer the canonical source for VdustR Agent Skills or plugin adapters.

Use [VdustR/skills](https://github.com/VdustR/skills) as the canonical repository. Installation and management should use `npx skills`.

## Installation Pointer

Preview available skills:

```bash
npx -y skills add VdustR/skills --list
```

Install all skills globally for Codex:

```bash
npx -y skills add VdustR/skills --skill '*' -g --agent codex
```

Install all skills globally for Claude Code:

```bash
npx -y skills add VdustR/skills --skill '*' -g --agent claude-code
```

## Maintenance Rules

- Do not add new skills, plugins, adapters, marketplace entries, or development workflows here.
- Do not treat `plugins/`, `skills/`, `.claude-plugin/`, or `.codex-plugin/` contents as current source material.
- Make new skill changes in `VdustR/skills`.
- If this repository must be temporarily unarchived, keep changes limited to deprecation pointers, license text, or archival metadata.
- Keep public-facing text in this repository directed to `VdustR/skills` and `npx skills`.

## Verification

Before committing any archival pointer change:

```bash
python3 -m json.tool .claude-plugin/marketplace.json >/dev/null
rg -n "VdustR/skills|npx skills|deprecated|archived" README.md AGENTS.md .claude-plugin/marketplace.json
git diff -- README.md AGENTS.md .claude-plugin/marketplace.json
```
