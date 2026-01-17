---
name: pr-comment-resolver
description: This skill should be used when the user asks to "handle PR comments", "resolve PR review comments", "fix PR feedback", "process review comments", "address PR suggestions", or provides a GitHub PR URL with review comments to handle. Automates the workflow of reviewing, fixing, and resolving PR comments with atomic commits.
---

# PR Comment Resolver

Automate the process of handling GitHub PR review comments: evaluate each comment, fix issues with atomic commits, and reply with detailed resolution information.

## Core Principles

1. **Atomic Commits** - Create one commit per logical fix, never bundle unrelated changes
2. **Smart Grouping** - When one commit fixes multiple comments, reply to all with the same commit info
3. **Human Collaboration** - Ask the user when uncertain about a fix or interpretation
4. **Detailed Replies** - Include fix explanation, commit hash, and link in every resolution
5. **Reply to Thread** - Always reply directly to each review thread, NOT as a general PR comment at the bottom

## Quick Start

### Interactive Mode (Default)

```
User: Handle the comments on this PR: https://github.com/owner/repo/pull/123
```

Workflow:
1. Fetch all unresolved review comments
2. Present each comment for review
3. For each comment, determine whether to fix or explain why no fix is needed
4. Execute fixes with atomic commits
5. Reply and resolve each comment

### Auto Mode

```
User: Auto-resolve all comments on https://github.com/owner/repo/pull/123
```

Process all comments automatically, only pausing for truly ambiguous cases.

## Workflow Overview

### Phase 1: Fetch Comments

Use `gh` CLI to retrieve all unresolved review comments:

```bash
gh pr view <PR_NUMBER> --json reviewThreads --jq '.reviewThreads[] | select(.isResolved == false)'
```

Extract key information:
- Comment ID and thread ID
- File path and line number
- Comment body (the feedback)
- Author information

### Phase 2: Evaluate Each Comment

For each unresolved comment, determine:

| Decision | Criteria |
|----------|----------|
| **Needs Fix** | Code issue, bug, style violation, missing feature |
| **No Fix Needed** | Already addressed, misunderstanding, design choice, out of scope |
| **Uncertain** | Ambiguous request, multiple interpretations, needs clarification |

### Phase 3: Execute Action

#### If Fix Needed

1. Read the relevant file(s)
2. Implement the fix
3. Create an atomic commit with descriptive message
4. Push to the PR branch
5. Reply with fix details and resolve

#### If No Fix Needed

1. Compose explanation of why no change is required
2. Reply with the explanation
3. Resolve the comment

#### If Uncertain

1. Present the comment to the user
2. Explain the ambiguity
3. Ask for guidance
4. Proceed based on user input

### Phase 4: Reply and Resolve

After each action, reply to the comment thread and resolve it.

> **⚠️ CRITICAL:** You MUST use the GraphQL `addPullRequestReviewThreadReply` mutation to reply directly to each review thread. Do NOT use `gh pr comment` as it posts to the PR bottom instead of the specific thread.

**Reply format for fixes:**

```markdown
- [<short-hash> <commit-message>](<commit-url>)

**Files modified:**
- `<file-path>`
```

Example:

```markdown
- [a1b2c3f fix(auth): add null check for user session](https://github.com/owner/repo/commit/a1b2c3f)

**Files modified:**
- `src/auth/session.ts`
```

**Reply format for no-fix:**

```markdown
No changes needed.

**Reason:** <explanation of why no fix is required>
```

### Phase 5: Summary Report

After processing all comments, output a summary report:

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

## GitHub CLI Commands

### Fetch PR Comments

```bash
# Get all review threads
gh pr view <NUMBER> --json reviewThreads

# Get unresolved threads only
gh pr view <NUMBER> --json reviewThreads --jq '[.reviewThreads[] | select(.isResolved == false)]'
```

### Reply to Comment

```bash
gh api graphql -f query='
  mutation($body: String!, $threadId: ID!) {
    addPullRequestReviewThreadReply(input: {
      pullRequestReviewThreadId: $threadId,
      body: $body
    }) {
      comment { id }
    }
  }
' -f threadId="<THREAD_ID>" -f body="<REPLY_BODY>"
```

### Resolve Thread

```bash
gh api graphql -f query='
  mutation {
    resolveReviewThread(input: {
      threadId: "<THREAD_ID>"
    }) {
      thread { isResolved }
    }
  }
'
```

## Commit Message Format

Follow conventional commit style:

```
fix(<scope>): <short description>

<detailed explanation if needed>

Addresses PR review comment by <author>
```

Example:

```
fix(auth): add null check for user session

The session object may be undefined when the user
is not logged in. Added defensive check to prevent
TypeError.

Addresses PR review comment by @reviewer
```

## Handling Multiple Comments with One Fix

When a single code change addresses multiple comments:

1. Make the fix and commit once
2. Reply to ALL related comments with the same content
3. Resolve all related threads

Example scenario:
- Comment A: "Add error handling here"
- Comment B: "This function should validate input"
- Both are in the same function

Resolution:
- One commit: `fix(validator): add input validation and error handling`
- Reply to both A and B with identical commit info
- Resolve both threads

## Decision Tree

```
Comment Received
      │
      ▼
┌─────────────────┐
│ Is it clear     │──No──▶ Ask user for clarification
│ what to fix?    │
└────────┬────────┘
         │Yes
         ▼
┌─────────────────┐
│ Is a code       │──No──▶ Reply with explanation, resolve
│ change needed?  │
└────────┬────────┘
         │Yes
         ▼
┌─────────────────┐
│ Does this fix   │──Yes─▶ Group with related comments
│ multiple items? │
└────────┬────────┘
         │No
         ▼
   Fix → Commit → Push → Reply → Resolve
```

## Important Guidelines

### DO

- Create atomic commits (one logical change per commit)
- Include commit links in replies
- Ask when uncertain
- Group related fixes
- Use conventional commit messages
- Verify fixes compile/pass linting before committing

### DON'T

- Bundle unrelated fixes in one commit
- Resolve without replying
- Make assumptions about ambiguous requests
- Force push or rewrite history
- Skip verification steps
- **Use `gh pr comment` for replies** - This posts to PR bottom, not to the review thread. Always use GraphQL `addPullRequestReviewThreadReply` for direct replies; use `gh pr comment` only as a fallback.

## Error Handling

| Error | Action |
|-------|--------|
| Comment already resolved | Skip and continue |
| File not found | Ask user for correct path |
| Commit fails | Report error, do not resolve |
| Push fails | Report error, suggest manual intervention |
| GraphQL API error | Retry once, then report to user |

## Additional Resources

### Reference Files

For detailed workflows and templates:

- **`references/workflow.md`** - Step-by-step workflow with examples
- **`references/reply-templates.md`** - Copy-paste reply templates for common scenarios

## Fallback Behavior

If the GraphQL API fails to reply to a thread (e.g., network error, permission issue, thread already resolved):

1. **Retry once** after a brief delay
2. **If retry fails**, fall back to `gh pr comment` with clear context:

```bash
gh pr comment <PR_NUMBER> --body "$(cat <<'EOF'
**Re: Review comment on `<FILE_PATH>:<LINE>`**

> <ORIGINAL_COMMENT_EXCERPT>

<YOUR_REPLY_CONTENT>

---
*Note: Unable to reply directly to the review thread. This is a fallback comment.*
EOF
)"
```

3. **Report to user** that the reply was posted as a general comment instead of a thread reply
4. **Continue processing** remaining comments

> **Important:** The fallback should only be used when GraphQL truly fails. Always attempt GraphQL first.

## Notes

- Requires `gh` CLI authenticated with appropriate permissions
- Works with GitHub PRs (GitLab/Bitbucket not supported)
- Branch must be checked out locally
- Respect repository's commit message conventions if defined
