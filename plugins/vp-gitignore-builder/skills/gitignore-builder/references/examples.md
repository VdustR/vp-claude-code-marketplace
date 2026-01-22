# Gitignore Builder Examples

## Example 1: New Node.js Project

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

## Example 2: Global Gitignore Request Inside a Repo

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

## Example 3: Merging with Existing Gitignore

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

## Example 4: Auto-trigger on Suspicious Files

```
User: git status

Claude: [observes output showing node_modules/ and .env in untracked files]

        ⚠️ Noticed potentially sensitive/generated files in git status:
        - node_modules/ (should typically be ignored)
        - .env (may contain secrets)

        Would you like me to create or update .gitignore to exclude these?
```
