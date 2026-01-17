# Reply Templates

Copy-paste templates for common PR comment resolution scenarios.

## Commit Link Format

Always use this format for commit links:

```markdown
- [{SHORT_HASH} {COMMIT_MESSAGE}]({COMMIT_URL})
```

Example:

```markdown
- [a1b2c3f fix(auth): add null check for user session](https://github.com/owner/repo/commit/a1b2c3f)
```

## Fix Applied Templates

### Standard Fix

```markdown
- [{SHORT_HASH} {COMMIT_MESSAGE}]({COMMIT_URL})

**Files modified:**
- `{FILE_PATH}`
```

### Fix with Explanation

```markdown
- [{SHORT_HASH} {COMMIT_MESSAGE}]({COMMIT_URL})

**Explanation:**
{WHY_THIS_APPROACH_WAS_CHOSEN}

**Files modified:**
- `{FILE_PATH}`
```

### Multiple Files Changed

```markdown
- [{SHORT_HASH} {COMMIT_MESSAGE}]({COMMIT_URL})

**Files modified:**
- `{FILE_PATH_1}`
- `{FILE_PATH_2}`
- `{FILE_PATH_3}`
```

### Fix Addressing Multiple Comments

```markdown
- [{SHORT_HASH} {COMMIT_MESSAGE}]({COMMIT_URL})

This commit also addresses related comments in this PR.

**Files modified:**
- `{FILE_PATH}`
```

## No Fix Needed Templates

### Already Addressed

```markdown
No changes needed.

**Reason:** This was already addressed in:
- [{HASH} {COMMIT_MESSAGE}]({URL})
```

### By Design

```markdown
No changes needed.

**Reason:** This is intentional. {EXPLANATION_OF_DESIGN_DECISION}

If you'd like to discuss this further, happy to continue the conversation.
```

### Out of Scope

```markdown
No changes in this PR.

**Reason:** This suggestion is valuable but falls outside the scope of this PR, which focuses on {CURRENT_PR_SCOPE}.

I've created issue #{ISSUE_NUMBER} to track this for a future improvement.
```

Or without creating an issue:

```markdown
No changes in this PR.

**Reason:** This is a good suggestion but would require changes beyond the scope of this PR. Would you like me to create a follow-up issue to track this?
```

### Misunderstanding

```markdown
No changes needed.

**Clarification:** {EXPLANATION_OF_WHAT_THE_CODE_ACTUALLY_DOES}

The current implementation handles {CASE} by {HOW_IT_HANDLES_IT}. Let me know if you have further concerns!
```

### Existing Behavior

```markdown
No changes needed.

**Reason:** The functionality you mentioned already exists:
- {WHERE_IT_EXISTS}
- {HOW_IT_WORKS}

See `{FILE_PATH}:{LINE_NUMBER}` for the implementation.
```

## Question Response Templates

### Technical Question

```markdown
Great question!

{DETAILED_EXPLANATION}

Key points:
- {POINT_1}
- {POINT_2}
- {POINT_3}

Let me know if you'd like more details on any of this.
```

### "Why" Question

```markdown
The reason for this approach:

{EXPLANATION}

**Trade-offs considered:**
- {ALTERNATIVE_1}: {WHY_NOT}
- {ALTERNATIVE_2}: {WHY_NOT}

The current approach was chosen because {MAIN_REASON}.
```

### Documentation Question

```markdown
You're right that this could use better documentation.

- [{SHORT_HASH} {COMMIT_MESSAGE}]({COMMIT_URL})

Let me know if this helps!
```

## Partial Fix Templates

### Fixed Part, Deferred Part

```markdown
Partially addressed:
- [{SHORT_HASH} {COMMIT_MESSAGE}]({COMMIT_URL})

**Deferred for later:**
- {DEFERRED_ITEM} - This requires {REASON_FOR_DEFERRAL}

Created issue #{ISSUE_NUMBER} to track the remaining work.
```

### Fixed Differently Than Suggested

```markdown
Addressed with a slightly different approach:
- [{SHORT_HASH} {COMMIT_MESSAGE}]({COMMIT_URL})

**Your suggestion:** {THEIR_SUGGESTION}

**Implemented approach:** {WHAT_WAS_DONE}

**Reason for difference:** {WHY_DIFFERENT_APPROACH}

Let me know if you'd prefer the original suggestion instead!
```

## Error/Blocker Templates

### Cannot Reproduce Issue

```markdown
I wasn't able to reproduce the issue you described.

**Steps I tried:**
1. {STEP_1}
2. {STEP_2}
3. {STEP_3}

**Result:** {WHAT_HAPPENED}

Could you provide more details about how to reproduce this?
```

### Blocked by External Factor

```markdown
Unable to address this at the moment.

**Blocker:** {WHAT_IS_BLOCKING}

**Options:**
1. {OPTION_1}
2. {OPTION_2}

What would you prefer?
```

### Needs More Information

```markdown
I'd like to fix this, but need some clarification:

- {QUESTION_1}
- {QUESTION_2}

Once I understand {WHAT_NEEDS_CLARITY}, I can proceed with the fix.
```

## Quick One-Liners

For simple, straightforward cases:

```markdown
- [{SHORT_HASH} {COMMIT_MESSAGE}]({COMMIT_URL})

Good catch!
```

```markdown
- [{SHORT_HASH} {COMMIT_MESSAGE}]({COMMIT_URL})

Thanks for the review!
```

```markdown
- [{SHORT_HASH} {COMMIT_MESSAGE}]({COMMIT_URL})
```

```markdown
No changes needed - {BRIEF_REASON}.
```

## Template Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `{SHORT_HASH}` | 7-character commit hash | `a1b2c3f` |
| `{COMMIT_MESSAGE}` | Full commit message | `fix(auth): add null check for user session` |
| `{COMMIT_URL}` | Full URL to commit | `https://github.com/owner/repo/commit/a1b2c3f` |
| `{FILE_PATH}` | Path to modified file | `src/auth/session.ts` |
| `{ISSUE_NUMBER}` | Related issue number | `42` |

## Tone Guidelines

### DO

- Be appreciative of feedback: "Good catch!", "Thanks for noticing!"
- Be clear and concise
- Provide context when helpful
- Offer to discuss further
- Use "I" statements: "I've fixed...", "I've added..."

### DON'T

- Be defensive about code
- Over-explain simple fixes
- Use dismissive language
- Leave comments unaddressed
- Be vague about what was changed

## Language Matching

Match the language of the reviewer when appropriate:

**If reviewer writes in Chinese:**

```markdown
- [{SHORT_HASH} {COMMIT_MESSAGE}]({COMMIT_URL})

**修改檔案：**
- `{FILE_PATH}`
```

**If reviewer writes in Japanese:**

```markdown
- [{SHORT_HASH} {COMMIT_MESSAGE}]({COMMIT_URL})

**変更ファイル：**
- `{FILE_PATH}`
```

Default to English if unsure.

## Summary Report Template

After processing all comments, output a summary:

```markdown
## PR Comment Resolution Summary

**PR:** #<number> - <title>
**Processed:** <total> comments

### Commits
- [<hash> <message>](<url>)
- [<hash> <message>](<url>)

### Statistics
| Status | Count |
|--------|-------|
| Fixed | <n> |
| No fix needed | <n> |
| Skipped | <n> |

### Details
| Comment | File | Action | Commit |
|---------|------|--------|--------|
| <summary> | `<path>` | Fixed | [<hash>](<url>) |
| <summary> | `<path>` | No fix | - |
```
