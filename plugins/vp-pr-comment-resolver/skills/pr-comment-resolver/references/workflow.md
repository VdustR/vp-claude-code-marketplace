# Detailed Workflow Reference

This document provides step-by-step instructions for processing PR review comments.

## Complete Workflow

### Step 1: Initialize Session

Before processing comments, gather essential information:

```bash
# Get PR details
gh pr view <NUMBER> --json number,title,headRefName,baseRefName,url

# Ensure on correct branch
git checkout <headRefName>
git pull origin <headRefName>
```

### Step 2: Fetch All Review Comments

Retrieve unresolved review threads:

```bash
gh pr view <NUMBER> --json reviewThreads --jq '
  [.reviewThreads[] | select(.isResolved == false) | {
    id: .id,
    path: .path,
    line: .line,
    comments: [.comments[] | {
      id: .id,
      author: .author.login,
      body: .body,
      createdAt: .createdAt
    }]
  }]
'
```

### Step 3: Build Comment Queue

Organize comments for processing:

```
Queue Structure:
[
  {
    threadId: "thread-1",
    filePath: "src/auth.ts",
    lineNumber: 42,
    originalComment: "Add null check here",
    author: "reviewer1",
    status: "pending"  // pending | processing | fixed | skipped | uncertain
  },
  ...
]
```

### Step 4: Process Each Comment

For each comment in the queue:

#### 4.1 Read Context

Use the **Read tool** to read file contents:

```
Read file: <filePath>

# For specific line ranges, use offset and limit parameters:
Read file: <filePath> (offset: <start>, limit: <count>)
```

> **Note:** In Claude Code, always use the Read tool instead of bash commands like `cat` or `sed` for reading files. The Read tool provides better integration and avoids permission issues.

#### 4.2 Analyze Comment

Determine action based on comment type:

| Comment Type | Example | Action |
|--------------|---------|--------|
| Bug fix request | "This will throw if x is null" | Fix and commit |
| Style suggestion | "Use const instead of let" | Fix and commit |
| Question | "Why is this needed?" | Reply with explanation |
| Design discussion | "Should this be a class?" | Ask user |
| Already done | "Add logging" (logging exists) | Reply explaining it's done |
| Out of scope | "Refactor entire module" | Reply explaining scope |

#### 4.3 Execute Fix (if needed)

```bash
# Make changes to file
# (Use Edit tool or manual editing)

# Stage changes
git add <filePath>

# Commit with descriptive message
git commit -m "fix(<scope>): <description>

Addresses PR review comment by @<author>"

# Get commit info for reply
COMMIT_HASH=$(git rev-parse --short HEAD)
COMMIT_URL="https://github.com/<owner>/<repo>/commit/$(git rev-parse HEAD)"
```

#### 4.4 Push Changes

```bash
git push origin <branchName>
```

### Step 5: Reply and Resolve

#### Using GraphQL API

```bash
# First, get the review ID from the thread
REVIEW_ID=$(gh api graphql -f query='
  query($owner: String!, $repo: String!, $number: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $number) {
        reviews(last: 1) {
          nodes { id }
        }
      }
    }
  }
' -f owner="<OWNER>" -f repo="<REPO>" -F number=<NUMBER> --jq '.data.repository.pullRequest.reviews.nodes[0].id')

# Add reply comment
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

# Resolve the thread
gh api graphql -f query='
  mutation($threadId: ID!) {
    resolveReviewThread(input: {
      threadId: $threadId
    }) {
      thread { isResolved }
    }
  }
' -f threadId="<THREAD_ID>"
```

### Step 6: Handle Grouped Fixes

When one commit fixes multiple comments:

1. Track all related thread IDs
2. Make the single fix
3. Create one commit
4. Loop through all related threads:
   - Reply with same commit info
   - Resolve each thread

```
Example:
Comment A (thread-1): "Validate input"
Comment B (thread-3): "Add error handling"
Comment C (thread-5): "Check for null"

All in same function → One fix addresses all three

Action:
1. Implement validation + error handling + null check
2. Commit: "fix(validator): add comprehensive input validation"
3. Reply to thread-1, thread-3, thread-5 with same commit link
4. Resolve all three threads
```

## Interactive Mode Flow

```
┌────────────────────────────────────────────────────────────┐
│                    INTERACTIVE MODE                         │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  For each comment:                                         │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ Comment #1 of 5                                       │ │
│  │ File: src/auth.ts:42                                  │ │
│  │ Author: @reviewer                                     │ │
│  │                                                       │ │
│  │ "Consider adding a null check for the session        │ │
│  │  object before accessing its properties"             │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  Options:                                                  │
│  [1] Fix this issue                                        │
│  [2] No fix needed (explain why)                           │
│  [3] Skip for now                                          │
│  [4] Discuss with user                                     │
│                                                            │
│  User selects → Execute → Next comment                     │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

## Auto Mode Flow

```
┌────────────────────────────────────────────────────────────┐
│                      AUTO MODE                              │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Processing 5 comments automatically...                    │
│                                                            │
│  [1/5] src/auth.ts:42 - Null check                        │
│        → Analyzing... Fix needed                           │
│        → Fixing... Done                                    │
│        → Committed: abc1234                                │
│        → Replied and resolved ✓                            │
│                                                            │
│  [2/5] src/api.ts:87 - Error handling                     │
│        → Analyzing... Fix needed                           │
│        → Fixing... Done                                    │
│        → Committed: def5678                                │
│        → Replied and resolved ✓                            │
│                                                            │
│  [3/5] src/utils.ts:15 - "Why this approach?"             │
│        → Analyzing... Question, no fix needed              │
│        → Replied with explanation ✓                        │
│        → Resolved ✓                                        │
│                                                            │
│  [4/5] src/config.ts:33 - Ambiguous request               │
│        → PAUSED: Need user input                           │
│        → [Asking user for clarification...]                │
│                                                            │
│  [5/5] Waiting...                                          │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

## Edge Cases

### Comment on Deleted Lines

If the comment references lines that no longer exist:

1. Check git history to understand context
2. Determine if the issue is already resolved by recent changes
3. Reply explaining the situation
4. Resolve with appropriate explanation

### Conflicting Comments

When two reviewers give contradictory feedback:

1. Do NOT attempt to resolve automatically
2. Present both comments to user
3. Ask for direction
4. Proceed only after clarification

### Large Refactoring Requests

When a comment suggests extensive changes:

1. Acknowledge the suggestion
2. Explain it's out of scope for this PR
3. Offer to create a follow-up issue
4. Resolve with the explanation

## Verification Checklist

Before resolving each comment:

- [ ] Fix is correct and complete
- [ ] Code compiles without errors
- [ ] Linting passes (if configured)
- [ ] Commit message is descriptive
- [ ] Changes are pushed to remote
- [ ] Reply includes commit link
- [ ] Reply explains the change

## Recovery from Errors

### Commit Failed

```bash
# Check status
git status

# If staged files have issues, fix them
# Then retry commit
git commit -m "..."
```

### Push Failed

```bash
# Pull latest changes
git pull origin <branch> --rebase

# Resolve any conflicts
# Then push again
git push origin <branch>
```

### GraphQL API Error

Common errors and solutions:

| Error | Cause | Solution |
|-------|-------|----------|
| 401 Unauthorized | Token expired | Re-authenticate with `gh auth login` |
| 404 Not Found | Wrong thread ID | Re-fetch thread IDs |
| 422 Unprocessable | Thread already resolved | Skip to next comment |
