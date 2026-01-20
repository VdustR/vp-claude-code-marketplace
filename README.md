# Claude Code Marketplace

Claude Code plugins by [VdustR](https://github.com/VdustR).

> All plugins in this marketplace use the `vp-` prefix (VdustR Plugin).

## Installation

```bash
/plugin marketplace add VdustR/vp-claude-code-marketplace
```

## Available Plugins

> Plugins are listed in alphabetical order.

### vp-add-skill

Manage agent skills installation with registry tracking.

```bash
/plugin install vp-add-skill@vdustr
```

Features:
- Install skills from any git repository using `npx add-skill`
- Track installed skills with a JSON registry
- Support for global, project (shared), and project (local) scopes
- JSON Schema validation for registry format

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
