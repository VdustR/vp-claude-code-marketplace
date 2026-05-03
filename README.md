# Agent Skills Marketplace (Deprecated)

> [!IMPORTANT]
> This repository is deprecated and archived. The canonical VdustR Agent Skills
> now live in [VdustR/skills](https://github.com/VdustR/skills).

Use `npx skills` to install and manage the current skills directly from
`VdustR/skills`.

## Installation

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

Install selected skills:

```bash
npx -y skills add VdustR/skills --skill vp-cspell --skill vp-gitignore-builder -g --agent codex
npx -y skills add VdustR/skills --skill vp-cspell --skill vp-gitignore-builder -g --agent claude-code
```

Install to the current project instead of globally by omitting `-g`.

## Status

- This repository is a read-only archive.
- New skills and updates should be made in [VdustR/skills](https://github.com/VdustR/skills).
- The marketplace/plugin adapter layout in this repository is retained only for historical reference.
- Do not use this repository as the source of truth for current skill installation.

## License

[MIT](LICENSE)
