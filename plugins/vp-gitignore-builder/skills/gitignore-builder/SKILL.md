---
name: gitignore-builder
description: Build and merge .gitignore files using github/gitignore templates with smart project detection. Use when user mentions gitignore, ignoring files, or when detecting projects without .gitignore.
---

# Gitignore Builder

Build and merge `.gitignore` files using templates from [github/gitignore](https://github.com/github/gitignore) with smart project detection.

## When to Use

Invoke this skill when:

- User explicitly requests `/gitignore` or asks to create/update a `.gitignore`
- Detecting `git init` or a newly cloned repo without `.gitignore`
- User mentions ignoring files, not wanting to track certain files
- Observing `git status` output with files that should typically be ignored (e.g., `node_modules/`, `.env`, `__pycache__/`, `*.log`)

## Workflow

### Step 1: Determine Target Location

1. Find the nearest `.git` directory to determine repo root
2. If no `.git` found, ask user if they want to create a global gitignore at `~`

**Location Rules:**

| Situation | Action |
|-----------|--------|
| Inside a repo, project-level requested | Use repo root (where `.git` is) |
| Inside a repo, global requested | Warn: "Global gitignore is recommended at `~/.gitignore`. You're currently inside a repo. Proceed here anyway?" |
| Not in a repo | Suggest creating global gitignore at `~/.gitignore` |

### Step 2: Detect Project Type

**For project-level gitignore (basic detection):**

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
| `CMakeLists.txt` | CMake.gitignore |
| `Makefile` with C/C++ files | C.gitignore or C++.gitignore |

**For global gitignore (environment-aware detection):**

| Detection Method | Template (from Global/) |
|------------------|-------------------------|
| `uname` = Darwin | macOS.gitignore |
| `uname` = Linux | Linux.gitignore |
| Windows environment | Windows.gitignore |
| `.vscode/` exists or `code` command available | VisualStudioCode.gitignore |
| `.idea/` exists | JetBrains.gitignore |
| `vim` or `nvim` available | Vim.gitignore |
| `emacs` available | Emacs.gitignore |

### Step 3: Present Recommendations

Show detected templates and ask for confirmation:

```
Detected project root: /path/to/repo
Found indicators: package.json, .vscode/

Recommended templates:
- Node.gitignore
- VisualStudioCode.gitignore (for global)

Proceed with these templates? [Y/n/edit]
```

Allow user to:
- Confirm (Y)
- Cancel (n)
- Edit the list (add/remove templates)

### Step 4: Fetch and Merge

Use the `merge-gitignore.sh` script located at `${CLAUDE_PLUGIN_ROOT}/scripts/merge-gitignore.sh`:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/merge-gitignore.sh" Node Python macOS
```

**Merge Order (later entries can override earlier ones):**

1. Existing `.gitignore` content (if any) - preserved at top with marker
2. Language/framework templates
3. Global templates (OS, IDE) - only for global gitignore
4. Recommended additions (`*.local`, `*.local.*`)

### Step 5: Handle EOL Conflicts

If the script detects mixed line endings:

```
⚠️ EOL inconsistency detected:
  - Node.gitignore: LF
  - VisualStudio.gitignore: CRLF
  - Existing .gitignore: LF

Choose unified format:
1. LF (Unix/macOS) - recommended
2. CRLF (Windows)
3. Keep as-is (no conversion)
```

Wait for user confirmation before proceeding.

### Step 6: Show Diff Preview

If target `.gitignore` already exists, show a diff:

```diff
📄 Will write to: /path/to/repo/.gitignore

--- Existing content
+++ Merged content

@@ -1,5 +1,50 @@
 # User custom rules
 my-custom-file.txt

+# ============================================
+# Source: https://github.com/github/gitignore/blob/main/Node.gitignore
+# ============================================
+node_modules/
+...

Confirm write? [Y/n]
```

### Step 7: Write File

After user confirms, write the file and report success:

```
✅ Created /path/to/repo/.gitignore (150 lines, 3 templates merged)
```

## Important Notes

### Always Recommend *.local Pattern

At the end of every gitignore generation, suggest:

```
💡 Tip: Consider adding these patterns for local configuration files:
   *.local
   *.local.*

These patterns prevent accidentally committing local overrides.
```

### Gitignore Syntax Reminders

When discussing or modifying gitignore:

- **Negation**: The exclamation mark prefix negates a pattern, re-including previously excluded files. Order is important: the negation must come after the exclusion. Example: `!important.log` re-includes `important.log`.
- **Order matters**: Later patterns override earlier ones.
- **Comments**: Lines starting with `#` are comments.
- **Directory**: Trailing `/` matches only directories (e.g., `build/`).
- **Wildcards**: `*` matches anything except `/`, `**` matches everything including `/`.

### Source Attribution

Every section from github/gitignore must include a source comment:

```gitignore
# ============================================
# Source: https://github.com/github/gitignore/blob/main/Node.gitignore
# ============================================
```

This helps users understand where each rule comes from and makes future maintenance easier.

### Preserve User Content

If merging with an existing `.gitignore`, preserve user-added content:

```gitignore
# ============================================
# User custom rules (preserved from original)
# ============================================
my-custom-rule.txt
secret-folder/

# ============================================
# Source: https://github.com/github/gitignore/blob/main/Node.gitignore
# ============================================
...
```

## Examples

### Example 1: New Node.js Project

```
User: /gitignore

Claude: Detected project root: /Users/dev/my-app
        Found: package.json

        Recommended templates:
        ✓ Node.gitignore

        Proceed with these templates? [Y/n/edit]

User: Y

Claude: Fetching Node.gitignore from github/gitignore...

        📄 Will write to: /Users/dev/my-app/.gitignore

        Preview (125 lines):
        # ============================================
        # Source: https://github.com/github/gitignore/blob/main/Node.gitignore
        # ============================================

        # Logs
        logs
        *.log
        npm-debug.log*
        ...

        # ============================================
        # Recommended by gitignore-builder
        # ============================================

        # Local configuration files
        *.local
        *.local.*

        Confirm write? [Y/n]

User: Y

Claude: ✅ Created /Users/dev/my-app/.gitignore
```

### Example 2: Global Gitignore Request Inside a Repo

```
User: Create a global gitignore for me

Claude: ⚠️ You're currently inside a git repository (/Users/dev/my-app).
        Global gitignore is recommended to be placed at ~/.gitignore

        Options:
        1. Create at ~/.gitignore (recommended)
        2. Create at /Users/dev/my-app/.gitignore

        Which do you prefer?

User: 1

Claude: Detecting environment...
        - OS: macOS (Darwin)
        - Editors: VS Code, Vim

        Recommended templates:
        ✓ Global/macOS.gitignore
        ✓ Global/VisualStudioCode.gitignore
        ✓ Global/Vim.gitignore

        Proceed? [Y/n/edit]
```

### Example 3: Merging with Existing Gitignore

```
User: Add Python ignores to my gitignore

Claude: Found existing .gitignore at /Users/dev/my-app/.gitignore (15 lines)

        Fetching Python.gitignore...

        📄 Merge preview:

        --- Existing (15 lines)
        +++ Merged (165 lines)

        @@ -1,15 +1,165 @@
         # ============================================
         # User custom rules (preserved from original)
         # ============================================
         .env
         secrets/

        +# ============================================
        +# Source: https://github.com/github/gitignore/blob/main/Python.gitignore
        +# ============================================
        +
        +# Byte-compiled / optimized / DLL files
        +__pycache__/
        +*.py[cod]
        ...

        Confirm merge? [Y/n]
```

### Example 4: Auto-trigger on Suspicious Files

```
User: git status

Claude: [observes output showing node_modules/ and .env in untracked files]

        ⚠️ Noticed potentially sensitive/generated files in git status:
        - node_modules/ (should typically be ignored)
        - .env (may contain secrets)

        Would you like me to create or update .gitignore to exclude these?
```

## Script Reference

The `merge-gitignore.sh` script handles:

1. Fetching templates from github/gitignore via raw.githubusercontent.com
2. Detecting and reporting EOL inconsistencies
3. Concatenating templates with source attribution
4. Outputting to stdout for preview/confirmation workflow

**Usage:**

```bash
# Fetch and merge templates
"${CLAUDE_PLUGIN_ROOT}/scripts/merge-gitignore.sh" <template1> [template2] ...

# Templates can be:
# - Top-level: Node, Python, Rust, Go, etc.
# - Global: Global/macOS, Global/VisualStudioCode, etc.
```

**Exit Codes:**

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Network error (failed to fetch) |
| 2 | EOL conflict detected (info in stderr) |
