# Conflict Resolution Reference

Basic guide for handling merge conflicts during cherry-pick operations.

## Conflict Classification

| Type | Example | Action |
|------|---------|--------|
| **Simple** | Import additions, whitespace, comments | Auto-resolve (keep both) |
| **Complex** | Same line modified, function signature changed | Ask user |

## During Conflict

```bash
# Check conflicted files
git status

# View conflict details
git diff

# After resolving
git add <resolved_file>
git cherry-pick --continue

# If need to abort
git cherry-pick --abort
```

## Recovery

If something goes wrong, restore from backup:

```bash
git reset --hard backup-pr<NUMBER>-<TIMESTAMP>
```

## Key Principle

When in doubt, **ask the user**. Don't auto-resolve semantic changes.
