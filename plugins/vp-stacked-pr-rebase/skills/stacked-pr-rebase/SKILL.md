---
name: stacked-pr-rebase
description: This skill should be used when the user asks to "rebase my PR after parent merged", "update stacked PR", "fix PR after dependency merged", "cherry-pick my commits to new base", "sync stacked PR", or when a PR contains commits from a merged parent PR that need to be removed. Automates rebasing dependent PRs while preserving only the user's own commits.
---

# Stacked PR Rebase

Automate rebasing of stacked PRs after their parent PR is merged. Identifies your commits, handles different merge types (regular, squash, rebase), and cherry-picks only your work onto the updated base.

## Core Principles

1. **Analyze Before Acting** - Always understand the dependency relationship and merge type before making changes
2. **Preserve User Work** - Only cherry-pick/rebase the user's own commits; never lose work
3. **Smart Detection** - Automatically detect parent PR and merge type when possible; ask user only when uncertain
4. **Handle Conflicts Gracefully** - Auto-resolve simple conflicts; ask user for complex semantic conflicts
5. **Safe Operations** - Always create backup branch; use `--force-with-lease`; require confirmation for force push
6. **Clear Reporting** - Show exactly what will happen before and after

## Quick Start

### Basic Usage

```
User: My PR depends on PR #123 which just got merged. Help me rebase.
```

Workflow:
1. Analyze current PR's commit history
2. Identify parent PR (from branch/commits analysis or ask user)
3. Detect how parent PR was merged (regular/squash/rebase)
4. Classify commits: "parent's" vs "your own"
5. Create backup branch
6. Cherry-pick your commits to updated base
7. Handle any conflicts
8. Force push with user confirmation
9. Generate summary report

### With Explicit Parent PR

```
User: Rebase my PR, parent was PR #456
```

## Workflow Overview

### Phase 1: Situation Analysis

Gather context about the current PR and identify the parent PR.

```bash
# Get current PR info
gh pr view <PR_NUMBER> --json number,title,headRefName,baseRefName,commits

# Find merge-base with target branch
git merge-base HEAD origin/<baseRefName>

# List commits from merge-base to HEAD
git log --oneline $(git merge-base HEAD origin/main)..HEAD

# Get recently merged PRs to find potential parent
gh pr list --state merged --base <baseRefName> --limit 20 \
  --json number,title,headRefName,mergeCommit,commits
```

**Detection Strategy (try in order):**

1. **Check commit containment** (most reliable for squash merge):
   - Get original commits from each recently merged PR via GitHub API
   - Check if current PR's commits **contain** those original commits
   - If current PR contains merged PR's original commits → that's the parent PR

   ```
   Merged PR #123 original commits (from API): A, B
   Current PR commits (from git log): A, B, C, D

   → Current PR contains A, B → Parent PR is #123
   → C, D are "your own" commits to keep
   ```

2. **Check branch relationship**: Look for branch naming patterns (e.g., `feature-x` → `feature-x-part2`)
3. **Check commit messages**: Look for PR references like `(#123)` in commit messages
4. **Ask user**: If no clear match, present candidates and ask

> **Note:** This strategy works regardless of how the parent PR was merged (regular, squash, or rebase), because we compare against the **original commits stored in GitHub API**, not against what's currently in main.

**Output:**
```
Situation Analysis:
- Current PR: #456 (feature-y)
- Base branch: main
- Potential parent PR: #123 (feature-x) - merged 2 hours ago
- Confidence: HIGH / MEDIUM / LOW
```

### Phase 2: Merge Type Detection

Determine how the parent PR was merged to choose the correct rebase strategy.

```bash
# Get parent PR's merge commit details
gh api graphql -f query='
{
  repository(owner: "<OWNER>", name: "<REPO>") {
    pullRequest(number: <PARENT_PR_NUMBER>) {
      mergeCommit {
        oid
        parents(first: 2) {
          nodes { oid }
        }
      }
      commits(first: 100) {
        nodes {
          commit { oid message }
        }
      }
    }
  }
}'
```

**Detection Logic:**

| Merge Type | Detection | Strategy |
|------------|-----------|----------|
| **Regular Merge** | `mergeCommit.parents` has 2 nodes | Cherry-pick own commits |
| **Squash Merge** | 1 parent + original commits not in main | Cherry-pick own commits |
| **Rebase Merge** | 1 parent + original commits rewritten in main | Cherry-pick own commits |

> **Note:** We use cherry-pick for ALL merge types for consistency and predictability.

```
Decision Tree:
                    mergeCommit.parents.length
                           │
            ┌──────────────┴──────────────┐
            │                              │
          2 parents                    1 parent
            │                              │
            ▼                              ▼
      REGULAR MERGE          Check if original commits in main
                                          │
                               ┌──────────┴──────────┐
                               │                      │
                          Not found            Found (rewritten)
                               │                      │
                               ▼                      ▼
                        SQUASH MERGE           REBASE MERGE
```

### Phase 3: Commit Classification

Identify which commits are "parent's" (to exclude) vs "your own" (to keep).

**Key Insight for Squash Merge:**
- The parent PR's original commits (A, B) still exist in your branch
- They were squashed in main, but GitHub API still has their SHAs
- Compare your branch commits against parent PR's original commits from API

```bash
# Get parent PR's original commits from GitHub API
gh api repos/<OWNER>/<REPO>/pulls/<PARENT_PR>/commits --jq '.[].sha'
# Output: aaa1111, bbb2222

# List all commits in current branch
git log --format="%H %s" $(git merge-base HEAD origin/main)..HEAD
# Output: aaa1111, bbb2222, ccc3333, ddd4444
```

**Classification Logic:**

```
Parent PR's original commits (from API): {aaa1111, bbb2222}
Current PR's commits (from git log):     [aaa1111, bbb2222, ccc3333, ddd4444]

For each commit in current PR:
  if commit.sha IN parent_pr_commits:
    → Parent commit → EXCLUDE
  else:
    → Your commit → KEEP
```

**Classification Rules:**

| Condition | Classification |
|-----------|---------------|
| SHA in parent PR's original commits list | Parent commit → Exclude |
| Commit message matches parent PR commit exactly | Parent commit (rebased) → Exclude |
| Everything else | **Your commit → Keep** |

**Output:**
```
Commit Classification:
┌──────────┬─────────────────────────────────────┬────────────┐
│ SHA      │ Message                             │ Type       │
├──────────┼─────────────────────────────────────┼────────────┤
│ aaa1111  │ feat(x): implement feature A        │ Parent (A) │
│ bbb2222  │ feat(x): implement feature B        │ Parent (B) │
│ ccc3333  │ feat(y): implement feature C        │ OWN ✓      │
│ ddd4444  │ feat(y): implement feature D        │ OWN ✓      │
└──────────┴─────────────────────────────────────┴────────────┘

Commits to cherry-pick: ccc3333, ddd4444
```

### Phase 4: Rebase Execution

Execute the rebase/cherry-pick operation with conflict handling.

**1. Preparation:**
```bash
# Fetch latest
git fetch origin <baseRefName>

# Create backup branch
git branch backup-pr<NUMBER>-$(date +%Y%m%d%H%M%S) HEAD
```

**2. Execute Strategy (same for ALL merge types):**

```bash
# Create temp branch from updated base
git checkout -b temp-rebase origin/<baseRefName>

# Cherry-pick own commits in order (oldest first)
git cherry-pick <own_commit_1> <own_commit_2> ...

# Replace original branch
git checkout <original_branch>
git reset --hard temp-rebase
git branch -D temp-rebase
```

> **Why cherry-pick for all?** Consistent, predictable behavior regardless of merge type. No surprises.

**3. Conflict Handling:**

See `references/conflict-resolution.md` for detailed conflict handling.

| Conflict Type | Example | Action |
|---------------|---------|--------|
| **Simple** | Import additions, whitespace | Auto-resolve |
| **Medium** | Adjacent line changes | Attempt auto, ask if fails |
| **Complex** | Same line modified, semantic changes | Ask user |

```bash
# During conflict, check status
git status

# View conflict details
git diff

# After resolving
git add <resolved_file>
git cherry-pick --continue
```

### Phase 5: Completion & Report

Verify, push, and report results.

**1. Verify:**
```bash
# Check commit history
git log --oneline -10

# Confirm file status
git status

# Compare with remote
git diff origin/<branch>..HEAD --stat
```

**2. Confirm Force Push:**

```
⚠️ Ready to force push to origin/<branch>

Changes:
- Removed parent commits: aaa1111, bbb2222
- Kept your commits: ccc3333 → ccc4444' (rebased)
                     ddd4444 → ddd5555' (rebased)

This will REPLACE the remote branch. Proceed? [y/N]
```

**3. Push:**
```bash
git push --force-with-lease origin <branch>
```

**4. Summary Report:**

```markdown
## Stacked PR Rebase Summary

**PR:** #456 - Feature Y
**Parent PR:** #123 - Feature X (merged via squash)

### Before
```
main ── A ── B ── [PR #123 squash] ──────────────────
                  ↑
                  └── A ── B ── C ── D  (your PR)
```

### After
```
main ── A ── B ── [PR #123 squash] ── C' ── D'  (rebased)
```

### Commits Preserved
| Original | Rebased | Message |
|----------|---------|---------|
| ccc3333  | ccc4444 | feat(y): implement feature C |
| ddd4444  | ddd5555 | feat(y): implement feature D |

### Actions Taken
1. ✅ Created backup branch: backup-pr456-20240115120000
2. ✅ Identified parent PR #123 (squash merged)
3. ✅ Classified 4 commits (2 parent, 2 own)
4. ✅ Cherry-picked 2 commits onto new base
5. ✅ Force pushed to origin/feature-y

### Conflicts Resolved
| File | Type | Resolution |
|------|------|------------|
| (none) | - | - |

### Next Steps
- [ ] Review the rebased PR
- [ ] Run CI checks
- [ ] Delete backup when satisfied: `git branch -D backup-pr456-20240115120000`
```

## Important Guidelines

### DO

- **Verify parent PR identification** before proceeding; ask user if uncertain
- **Always create backup branch** before any destructive operation
- **Use `--force-with-lease`** instead of `--force` for safety
- **Require user confirmation** before force pushing
- **Handle all three merge types** (regular, squash, rebase)
- **Preserve commit messages** and authorship when cherry-picking
- **Report clearly** what was done and what commits were affected

### DON'T

- **Don't assume parent PR** without verification; ask if confidence is low
- **Don't force push without confirmation**
- **Don't lose commits** - always classify carefully
- **Don't auto-resolve complex conflicts** - ask user for semantic changes
- **Don't delete backup branch automatically** - let user decide
- **Don't proceed if unsure** about commit classification

## Error Handling

| Error | Action |
|-------|--------|
| Cannot identify parent PR | Ask user to specify PR number |
| Parent PR not yet merged | Abort with message; suggest waiting |
| No own commits found | Warn user; may already be rebased |
| Cherry-pick conflict | Classify and handle (auto/ask) |
| Own commit is a merge commit | Skip or use `cherry-pick -m 1`; ask user |
| Force push rejected | Check if branch protection; suggest user intervention |
| Backup branch exists | Use timestamp suffix for uniqueness |

## Additional Resources

- **`references/merge-strategies.md`** - Detailed merge type detection and handling
- **`references/conflict-resolution.md`** - Conflict classification and resolution strategies

## Notes

- Requires `gh` CLI authenticated with appropriate permissions
- Works with GitHub PRs (GitLab/Bitbucket not supported)
- Branch must be checked out locally
- Git 2.38+ recommended for `--update-refs` support
- Always test with a backup before critical operations
