# Checkbox Update Rules

Ownership detection, permission rules, and update mechanics for Phase 4 checkbox updates.

## Ownership Detection

### Get Current User

```bash
gh api user --jq '.login'
```

### Compare with Post Author

Each checklist source (PR body, comment) has an author from Phase 1. Compare:

```text
current_user = gh api user --jq '.login'
post_author  = (from Phase 1 data)

is_own_post = (current_user == post_author)
```

### Bot Detection

An author is a bot if:

1. **Login ends with `[bot]`**: `dependabot[bot]`, `github-actions[bot]`, `renovate[bot]`
2. **Known bot services** (case-insensitive match):
   - `dependabot`, `renovate`, `github-actions`
   - `copilot`, `coderabbitai`, `codiumai`, `sourcery-ai`
   - `deepsource`, `sonarcloud`, `codeclimate`, `snyk`

```bash
# Detection logic
author_lower=$(echo "$author" | tr '[:upper:]' '[:lower:]')
is_bot=false

if [[ "$author_lower" =~ \[bot\]$ ]]; then
  is_bot=true
elif [[ "$author_lower" =~ ^(dependabot|renovate|github-actions|copilot|coderabbitai|codiumai|sourcery-ai|deepsource|sonarcloud|codeclimate|snyk)$ ]]; then
  is_bot=true
fi
```

## Permission Detection

### Check Repository Write Access

```bash
gh api repos/{o}/{r} --jq '.permissions.push // false'
# Returns: true or false
# Note: .permissions may be null for fine-grained PATs without metadata:read scope
# If null/absent, treat as no write access (the `// false` fallback handles this)
```

### Permission Matrix

| Condition | `is_own_post` | `has_push` | `is_bot` |
|-----------|:---:|:---:|:---:|
| Auto-check | true | any | false |
| Suggest-then-check | false | true | false |
| Comment-only | false | false | any |
| Comment-only | any | any | true |

## Update Decision Matrix

| Post Owner | Permission | Default Behavior | User Override |
|------------|-----------|-----------------|--------------|
| **Self** | Any | Auto-check passed items | — |
| **Other (human)** | Push access | Suggest user self-operate | "Check them for me" → edit |
| **Other (human)** | No access | Comment with verification report | — |
| **Bot** | Any | Comment with verification report | "Check them for me" → edit (if has push) |

### Interaction Examples

**Own post — auto-check:**
```text
Checking off 5 passed items in your PR body...
Updated PR #123 body: 5 items checked.
```

**Other's post — suggest:**
```text
PR #123 body was authored by @other-user.
Default: I'll post a verification report as a comment.

Options:
1. Post verification report as comment (recommended)
2. Check off items directly (I have write access)
3. Skip updating — just show me the results

Which option? [1/2/3]
```

**No access — comment only:**
```text
You don't have write access to this repository.
I'll post a verification report as a comment instead.
```

## Race Condition Prevention

### Timestamp Comparison

Phase 1 saves `updated_at` for each source. Before PATCH in Phase 4:

```bash
# Re-fetch current body AND updated_at in a SINGLE API call
result=$(gh api repos/{o}/{r}/pulls/{n} --jq '{body, updated_at}')
# For issues: gh api repos/{o}/{r}/issues/{n} --jq '{body, updated_at}'
# For comments: gh api repos/{o}/{r}/issues/comments/{id} --jq '{body, updated_at}'

current_updated_at=$(echo "$result" | jq -r '.updated_at')

# Compare with Phase 1 timestamp
if [ "$current_updated_at" != "$phase1_updated_at" ]; then
  echo "Source has been modified since we started."
  echo "Skipping checkbox update for THIS source."
  echo "Please re-run /checklist to get fresh data for this source."
  # Continue with other unaffected sources
fi
```

> **TOCTOU note**: There is a residual race window between this GET and the subsequent PATCH. GitHub API has no conditional-write (ETag/If-Match) support for body updates. This timestamp check is best-effort — it reduces but does not eliminate the risk. After PATCH, optionally re-fetch to verify the update applied correctly.

### Rules

1. **Always compare timestamps** before every PATCH operation
2. **Fetch body AND timestamp in a single API call** — avoid mini-race between separate calls
3. **If timestamps differ** → skip this source's PATCH; continue with other sources
4. **Notify user** with clear message about which source was skipped
5. **Suggest re-running** the skill to get fresh data for skipped sources

## Update Mechanics

### PR Body Update

> **CRITICAL: Do NOT use shell `sed` or `echo` for checkbox replacement.** PR body content may contain shell metacharacters (backticks, `$()`, sed delimiters) that would cause injection or corruption. Use `jq` pipelines piped to `gh api --input -` to keep content in JSON throughout — this avoids shell expansion entirely.

```bash
# 1. GET current body + updated_at in a single call
result=$(gh api repos/{o}/{r}/pulls/{n})

# 2. Compare updated_at (see Race Condition Prevention)
current_updated_at=$(echo "$result" | jq -r '.updated_at')

# 3. Replace checkboxes and build JSON payload in a single jq pipeline
#    This keeps the body in JSON throughout, avoiding shell escaping entirely
echo "$result" | jq '{body: (.body | gsub("- \\[ \\] Item that passed"; "- [x] Item that passed"))}' \
  | gh api repos/{o}/{r}/pulls/{n} -X PATCH --input -
```

### Issue Body Update

```bash
# Same pattern as PR body, using issues endpoint
echo "$result" | jq '{body: (.body | gsub("- \\[ \\] Passed item"; "- [x] Passed item"))}' \
  | gh api repos/{o}/{r}/issues/{n} -X PATCH --input -
```

### Comment Update

```bash
# 1. GET current comment (body + updated_at in single call)
result=$(gh api repos/{o}/{r}/issues/comments/{comment_id})

# 2. Compare updated_at (see Race Condition Prevention)

# 3. Replace checkboxes and PATCH — same jq pipeline pattern
echo "$result" | jq '{body: (.body | gsub("- \\[ \\] Passed item"; "- [x] Passed item"))}' \
  | gh api repos/{o}/{r}/issues/comments/{comment_id} -X PATCH --input -
```

### Batching

- **One PATCH per source**: Group all checkbox updates for the same body/comment into a single PATCH
- **Order**: Update PR/issue body first, then comments (oldest first)
- **Per-source abort on race condition**: If a source has a timestamp mismatch, skip only that source and continue with others; report which sources were skipped

## Comment Report Template

When posting a verification report as a comment (instead of editing checkboxes):

```markdown
## Checklist Verification Report

<!-- Generated by checklist-runner -->

| Status | Item | Evidence |
|--------|------|----------|
| ✅ PASS | ~~Plugin name has `vp-` prefix~~ | `jq -r '.name' plugin.json` → `vp-checklist-runner` |
| ✅ PASS | ~~Tests pass~~ | CI: all 12 checks passed |
| ❌ FAIL | **No secrets in code** | Found potential key in `src/config.ts:42` |
| ⏳ PENDING | Lint passes | CI check still running |
| ⏭️ SKIP | Design reviewed | Requires human verification |

**Summary:** 4/6 passed | 1 failed | 1 pending

---
*Generated by [checklist-runner](https://github.com/VdustR/vp-claude-code-marketplace) with [Claude Code](https://claude.com/claude-code)*
```

### Comment Placement

Use `gh api` with JSON wrapping for both PRs and issues (PRs are issues in GitHub API):

```bash
# Wrap report in JSON and post — safe for any content
jq -n --arg body "$report" '{"body": $body}' \
  | gh api repos/{o}/{r}/issues/{n}/comments --input -
```

### Updating Existing Report

If a previous checklist-runner comment exists (detected by `<!-- Generated by checklist-runner -->` marker):
- Update the existing comment instead of creating a new one
- Use the comment's `id` for PATCH
