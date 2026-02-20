---
name: checklist-runner
description: >-
  Parse and verify checklists from GitHub PRs and issues, auto-checking items
  that pass verification. Use when asked to verify PR/issue checklists, check off
  items, process checklist tasks, or when a PR/issue contains unchecked items
  that need verification.
---

# Checklist Runner

Parse and verify GitHub PR/issue checklists, auto-checking items that pass verification. Classifies each checklist item, runs the cheapest verification possible, and checks off what passes — asking the user only when truly necessary.

## Core Principles

1. **Classify Before Executing** — Categorize every item before verification to pick the cheapest strategy
2. **CI-First for Tests** — Check CI status before running locally; avoid redundant work
3. **Confidence-Based Automation** — HIGH confidence items auto-proceed; MEDIUM/LOW confidence items pause for user
4. **Ownership-Aware Updates** — Respect GitHub permissions; never silently modify someone else's content
5. **Safe Operations** — Use `updated_at` to prevent race conditions; default to comment mode for others' posts

## Quick Start

```text
/checklist             # Auto-detect current branch's PR
/checklist #123        # Specific PR or issue number
/checklist <url>       # Specific PR or issue URL
```

## When to Use

- User asks to "verify the checklist", "check off items", "run the checklist", "process checklist"
- A PR or issue contains `- [ ]` unchecked items that need verification
- User wants to auto-check items that pass verification before merging
- User wants a verification report on checklist completion status

**When NOT to use**: For creating new checklists from scratch (just write markdown). For PR review comments, use `pr-comment-resolver` instead.

## Workflow Overview

| Phase | Name | Purpose |
|-------|------|---------|
| 1 | Source Resolution + Permission Probe | Auto-detect PR/issue, fetch body + comments, parse checklist items, detect ownership + permissions |
| 2 | Item Classification | Classify each unchecked item into Auto / CI / Shell / Scan / Human |
| 3 | Verification Execution | Execute verifications: Auto (instant) → CI (one-time check) → Shell (grep/jq) → Scan (subagents) → Human (batched questions) |
| 4 | Checkbox Update | Apply ownership rules: own post → auto-check; other's post → suggest or comment mode |
| 5 | Summary Report | Per-item status table, statistics, failed items with evidence, next steps |

### Phase 1: Source Resolution + Permission Probe

Determine the target PR/issue, fetch all checklist sources, and probe permissions upfront.

**Source Resolution Decision Tree:**

```text
Input received
      │
      ├── Explicit URL
      │   └── Parse owner/repo/type/number from URL
      │
      ├── #N (number)
      │   └── gh api repos/{o}/{r}/issues/{n} → detect PR vs issue
      │       (PRs are also issues in GitHub API; check for pull_request key)
      │
      └── Nothing provided
          └── gh pr view --json number,title,body,url
              ├── Success → use current branch's PR
              └── Failure → ask user to specify
```

**Fetch Checklist Sources:**

Collect all checklist items from the PR/issue body and comments. Use `gh pr view` for the PR body and GraphQL for comments. See [verification-recipes.md](references/verification-recipes.md) for exact API endpoints and queries.

> **Pagination**: GraphQL queries use `first: 100`. When results have `pageInfo.hasNextPage == true`, paginate with `after: endCursor` to avoid silently dropping later comments. Emit a warning if pagination is needed.

> **API field naming**: `gh pr view --json` uses camelCase (`updatedAt`), while REST `gh api` returns snake_case (`updated_at`). Normalize to `updated_at` internally.

**Parse Checklist Items:**

Extract all `- [ ]` and `- [x]` items from each source.

**Important**: Before extracting, strip fenced code blocks (`` ``` ... ``` ``) and inline code spans to avoid parsing example checklists inside code as real items.

Track for each item:
- Item text (normalized, trimmed)
- Checked state (unchecked = needs verification)
- Source (body vs comment ID)
- Source author
- Source `updated_at` timestamp (for race condition prevention in Phase 4)
- Nesting level (indented items are nested under a parent)

**Permission Probe:**

```bash
# Get current authenticated user
gh api user --jq '.login'

# Check repo write access
gh api repos/{o}/{r} --jq '.permissions.push'
```

Compare current user with each checklist source author. Detect bots:
- Author login ends with `[bot]`
- Known bot patterns: `dependabot`, `renovate`, `github-actions`, `copilot`
- For more reliable detection, check GraphQL `__typename` (`User` vs `Bot`) or REST `type` field

> **Null permissions**: If `.permissions` is null or absent (e.g., fine-grained PAT without `metadata:read`), treat as no write access.

**Output update mode to user:**

| Post Owner | Permission | Update Mode |
|------------|-----------|-------------|
| Self | Any | Auto-check (own post) |
| Other (human) | Push access | Suggest-then-check (suggest user self-operate; check only if explicitly requested) |
| Other (human) | No access | Comment-only (no write access) |
| Bot | Any | Comment-only (bot PR) |

```text
Source Analysis:
- PR #123 body: 8 unchecked items, author: @you → auto-check mode
- Comment by @reviewer: 3 unchecked items → suggest-then-check mode
- Total: 11 unchecked items to verify
```

**Edge Cases:**
- PR is closed/merged → warn user; ask if proceed anyway
- No checklist found → report "No checklist items found" and exit
- All items already checked → report; offer `--force` to re-verify (re-classify and re-verify all items regardless of checked state)
- Nested checklists → flatten with parent context preserved; verify each item independently but note its parent condition

### Phase 2: Item Classification

Classify each unchecked item to determine verification strategy. See [classification-patterns.md](references/classification-patterns.md) for full pattern reference.

**5 Classification Categories:**

| Category | Description | Example Items |
|----------|-------------|---------------|
| **Auto** | Verifiable with file/field checks | "Plugin name has `vp-` prefix", "SKILL.md has valid frontmatter" |
| **CI** | Verifiable via CI status check | "Tests pass", "Lint passes", "Build succeeds" |
| **Shell** | Verifiable with a single grep/find/jq | "No console.log left", "No TODO comments", "No `debugger` statements" |
| **Scan** | Needs semantic understanding (subagent) | "No secrets in code", "Documentation updated", "Changelog entry added" |
| **Human** | Cannot be automatically verified | "Design reviewed", "PM approved", "UX looks good" |

**Classification**: Normalize item text → match against patterns in priority order (Auto > CI > Shell > Scan > Human) → assign confidence. See [classification-patterns.md](references/classification-patterns.md) for the full algorithm, regex patterns, and disambiguation rules.

- HIGH confidence → auto-proceed
- MEDIUM/LOW → present classification to user for confirmation

**Output:**

```text
Item Classification (confidence = how sure we are about the category, not the verification result):
┌───┬─────────────────────────────────────┬──────────┬────────────┐
│ # │ Item                                │ Category │ Confidence │
├───┼─────────────────────────────────────┼──────────┼────────────┤
│ 1 │ Plugin name has `vp-` prefix        │ Auto     │ HIGH       │
│ 2 │ Tests pass                          │ CI       │ HIGH       │
│ 3 │ No console.log statements           │ Shell    │ HIGH       │
│ 4 │ No secrets in code                  │ Scan     │ HIGH       │
│ 5 │ Design reviewed by team             │ Human    │ HIGH       │
│ 6 │ Code quality is good                │ Human    │ LOW        │
└───┴─────────────────────────────────────┴──────────┴────────────┘

⚠️ Item #6 has LOW confidence. Confirm category or reclassify? [Human/Shell/Scan]
```

### Phase 3: Verification Execution

Execute verifications in cost order: Auto (instant) → CI (one API call) → Shell (single command) → Scan (subagents, confirm first) → Human (batched questions).

See [verification-recipes.md](references/verification-recipes.md) for specific commands and subagent prompts.

**Auto Verification:**

Run specific file/field checks. Each produces a definitive PASS/FAIL.

```bash
# Example: "Plugin name has vp- prefix"
jq -r '.name' plugin.json | grep -q '^vp-'

# Example: "Plugins sorted alphabetically"
jq -r '.plugins[].name' .claude-plugin/marketplace.json | sort -C
```

**CI Verification (one-time check, NO polling):**

```bash
gh pr checks <N> --json name,state,conclusion
```

| CI State | Action |
|----------|--------|
| All passed | PASS |
| Any failed | FAIL (show which checks failed) |
| Pending | Offer options: (1) skip, mark PENDING (2) wait and re-run skill later (3) run locally if user requests |
| No CI configured | Offer local execution with user confirmation |

**Shell Verification:**

Run single-command checks (grep, find, jq). Expected exit code 0 = PASS.

> **Source directories**: Detect the project's source directories from `tsconfig.json`, `package.json`, or directory structure rather than hardcoding `src/`. Verify target directory exists before running — a missing directory silently returns PASS.

```bash
# Example: "No console.log statements"
! grep -rn 'console\.log' src/

# Example: "No TODO comments"
! grep -rn 'TODO\|FIXME' src/
```

**Scan Verification (subagents):**

For items requiring semantic understanding. **Must confirm with user before launching.**

```text
Will launch 3 scan subagents for:
1. Secret detection scan
2. Documentation completeness check
3. Changelog entry verification

Proceed? [y/N]
```

- Max 5 subagents per execution
- Each subagent runs as a Task with `subagent_type=Explore`
- Returns PASS/FAIL with evidence
- **Scan results always have MEDIUM confidence** (never HIGH) — subagents can hallucinate; require user confirmation before checking off Scan-verified items, even on own posts

**Human Verification:**

Batch all Human items into a single prompt:

```text
The following items need manual verification:
1. "Design reviewed by team" — Has this been reviewed?
2. "PM approved" — Has PM given approval?

For each, reply: pass / fail / skip
```

**Confidence Scoring per Result:**

| Confidence | Meaning |
|------------|---------|
| HIGH | Definitive pass/fail (exact command output) |
| MEDIUM | Pattern-based (possible false positive/negative) |
| LOW | Heuristic or user-reported |

### Phase 4: Checkbox Update

Apply ownership rules determined in Phase 1 to update checkboxes. See [checkbox-update-rules.md](references/checkbox-update-rules.md) for full rules, update mechanics, and comment report template.

**Update Flow (5 steps):**

1. `gh api` GET current body/comment — fetch both `body` and `updated_at` in a **single API call**
2. Compare `updated_at` with Phase 1 timestamp
3. If changed → **abort update for this source**, notify user (continue with other unaffected sources)
4. If unchanged → string-replace `- [ ]` to `- [x]` for passed items
5. PATCH entire body (batch per source — one PATCH per body/comment)

> **Safety**: Checkbox replacement must use `jq` pipelines piped to `gh api --input -`, not shell `sed` or string interpolation — PR body content may contain shell metacharacters that would cause injection or corruption. Keep content in JSON throughout.

Ownership rules from the Phase 1 permission probe determine update behavior. See [checkbox-update-rules.md](references/checkbox-update-rules.md) for the full decision matrix, interaction examples, and comment report template.

### Phase 5: Summary Report

Generate final report after all verifications and updates:

```markdown
## Checklist Verification Summary

**Source:** PR #123 - Feature implementation
**Items:** 11 total (8 unchecked → verified)

### Results

| # | Item | Category | Result | Confidence | Updated |
|---|------|----------|--------|------------|---------|
| 1 | Plugin name has `vp-` prefix | Auto | PASS | HIGH | ✅ Checked |
| 2 | Tests pass | CI | PASS | HIGH | ✅ Checked |
| 3 | No console.log | Shell | PASS | HIGH | ✅ Checked |
| 4 | No secrets | Scan | FAIL | MEDIUM | — |
| 5 | Design reviewed | Human | PASS | LOW | ✅ Checked |
| 6 | Lint passes | CI | PENDING | — | — |

### Statistics
- **Passed:** 4/6 verified items
- **Failed:** 1 (with evidence above)
- **Pending:** 1 (CI still running)
- **Already checked:** 3 (skipped)

### Failed Items
1. **No secrets in code** — Found potential API key in `src/config.ts:42`. Please review and remove before merging.

### Next Steps
- Fix the failed item (#4) and re-run `/checklist`
- CI check (#6) is pending — re-run after CI completes
```

## Important Guidelines

### DO

- **Confirm before launching scan subagents** — they consume resources
- **Batch human questions** — one prompt for all Human items
- **Report evidence** for every PASS and FAIL — traceability matters
- **Confirm scan results with user** — scan subagents have MEDIUM confidence; never auto-check without user approval

### DON'T

- **Poll CI repeatedly** — one-time check only; offer to re-run later
- **Auto-edit other people's posts** — always default to suggest or comment
- **Launch unlimited subagents** — cap at 5 per execution
- **Pipe PR body through shell** — use `jq` pipelines with `gh api --input -` to keep content in JSON throughout
- **Force-check on race condition** — abort the affected source and notify user

## Error Handling

| Error | Action |
|-------|--------|
| No checklist found | Report "No checklist items found" and exit |
| All items already checked | Report; offer `--force` to re-verify |
| PR is closed/merged | Warn; ask if proceed anyway |
| Different repo URL | Extract owner/repo, verify `gh` access |
| CI failing | Report which checks failed, mark as FAIL |
| CI pending | One-time check; offer: skip / wait-and-rerun / local |
| No CI configured | Suggest local execution with detected commands |
| No edit permission | Comment-based verification report |
| Bot PR | Default to comment mode |
| Race condition (`updated_at` changed) | Abort PATCH entirely, notify user |
| Large PR with many scan items | Cap at 5 subagents; confirm before launching |
| GraphQL API error | Retry once; fall back to REST API if available |
| `gh` CLI not configured | Report prerequisite; suggest `gh auth login` |

## Reference Files

- [classification-patterns.md](references/classification-patterns.md) — Item classification rules, keyword patterns, confidence assignment
- [verification-recipes.md](references/verification-recipes.md) — Verification commands, subagent prompts, API endpoints
- [checkbox-update-rules.md](references/checkbox-update-rules.md) — Ownership detection, permission rules, update mechanics

## Notes

- Requires `gh` CLI authenticated with repo read access (write access for auto-checking)
- Works with GitHub PRs and issues (GitLab/Bitbucket not supported)
- GHES support is best-effort — some instances disable GraphQL or have different pagination limits; test against your target instance
- Fine-grained PATs need `issues:write` or `pull_requests:write` for checkbox editing, `metadata:read` for permission probe
- Mixed checklists across multiple comments are supported — each source is tracked and updated independently
- Re-running the skill on the same PR is safe — already-checked items are skipped unless `--force` is used
- `--force` re-classifies and re-verifies all items regardless of checked state
- Race condition prevention is best-effort (TOCTOU between GET and PATCH) — GitHub API has no conditional-write support; the `updated_at` check reduces but does not eliminate the race window
