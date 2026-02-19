---
name: review-loop
description: >-
  Iterative multi-pass subagent code review with fix-review loop.
  Use when asked to "review this code", "review my changes", "multi-pass review",
  "run 3-pass review", "review loop", "subagent review", "deep code review",
  "review this diff", "optimize this code", "review and fix loop",
  or when another skill needs subagent review as fallback,
  or when high-stakes code changes (pre-merge, pre-deploy, critical features)
  require thorough multi-perspective review.
  Boundary: for quick single-pass reviews, use built-in code-reviewer agents directly.
---

# Review Loop

Iterative multi-pass subagent code review with fix-review loop. Three built-in review passes catch different categories of issues, with context-aware suggested passes for deeper coverage. Fixes are applied and affected passes re-run until clean.

## Quick Start

> Review this code

> Multi-pass review my changes

> Deep review before merge

> Review and fix loop on src/auth/

## When to Use

- Code changes need thorough multi-perspective review (not just a quick glance)
- High-stakes changes: pre-merge, pre-deploy, security-sensitive, critical features
- Another skill needs subagent review as a fallback verification step
- User wants iterative optimization: review → fix → review → fix until clean
- Multiple files or complex logic that benefits from specialized review angles

**When NOT to use**: For quick single-pass reviews, use built-in code-reviewer agents directly (e.g., `feature-dev:code-reviewer`, `pr-review-toolkit:code-reviewer`). Use review-loop when thoroughness matters or when optimizing code through multiple review cycles.

## Workflow

### Phase 1: Target Identification

Determine what to review:

| Source | How to Get It |
|--------|--------------|
| Specific files | User provides paths |
| Staged changes | `git diff --cached` |
| Unstaged changes | `git diff` |
| PR diff | `gh pr diff <number>` |
| Recent commits | `git diff HEAD~N..HEAD` |
| Directory | Glob all relevant files |

If ambiguous, ask the user what scope to review.

### Phase 2: Reviewer Configuration

**Built-in passes** (always run all 3 unless user overrides):

| Pass | Focus | What It Catches |
|------|-------|-----------------|
| Direct | Correctness | Syntax errors, import issues, type errors, logic bugs, null safety, missing returns |
| Best Practice | Quality | Idiomatic patterns, performance issues, readability, DRY violations, naming |
| Critical Think | Risk | Edge cases, security vulnerabilities, race conditions, hidden assumptions, failure modes |

See [review-passes.md](references/review-passes.md) for full pass specifications and subagent prompt templates.

**Suggested passes**: After scanning the review target, suggest relevant optional passes based on detected signals. See [review-passes.md](references/review-passes.md) for all available suggested passes and their trigger conditions.

| Suggested Pass | Trigger Signals |
|---------------|-----------------|
| Testability | Test files in scope, logic-heavy code without tests, high branching |
| Accessibility | JSX/TSX with interactive elements, HTML forms, ARIA attributes present |
| API Surface | Exported functions/types, library entry points, OpenAPI/GraphQL schemas |
| Performance | DB queries, loops over collections, React render-heavy components, I/O in hot paths |
| i18n | Hardcoded user-facing strings, locale-sensitive operations, existing i18n setup |
| Concurrency | Async patterns with shared state, workers, DB transactions, event-driven code |

Present matching suggestions to the user — they choose which to enable:
- **all**: Enable all suggested passes
- **pick**: User selects specific passes from the suggestions
- **none**: Run only the 3 built-in passes

Suggested passes run in parallel alongside built-in passes and follow the same finding format, fix & iterate loop, and severity rules.

**Custom passes**: Users can also request arbitrary review angles not in the suggested list. Specify as custom subagent type or describe the review focus.

**External reviewers**: Users can request manual paste mode — generate a formatted review prompt for external AI tools. See [review-passes.md](references/review-passes.md) for the manual paste template.

### Phase 3: Review Execution

Run each pass as an **independent subagent** (parallel when possible):

1. Launch 3 subagents (one per pass) using the Task tool
2. Each subagent receives: code content + pass-specific prompt from [review-passes.md](references/review-passes.md)
3. Collect findings from all passes

**Finding format** (each subagent must return findings in this structure):

```
| # | Pass | Severity | Location | Issue | Suggested Fix |
```

- **Severity**: HIGH (must fix), MEDIUM (should fix), LOW (consider fixing)
- **Location**: `file:line` or `file:function_name`

### Phase 4: Fix & Iterate

See [loop-control.md](references/loop-control.md) for iteration limits and exit conditions.

**Fix authorization**:
- LOW/MEDIUM severity: auto-fix directly
- HIGH severity: present to user before fixing
- Ambiguous fixes (spanning > 5 lines, crossing function boundaries, or involving API interface changes): present to user before fixing

**After fixing**:
1. Re-run only the passes whose findings were fixed
2. Re-run Critical Think only when HIGH severity findings were fixed OR when Best Practice changes touch security-sensitive code regions (auth, crypto, input validation, database queries)
3. Repeat until clean or max iterations reached

**Exit conditions** (see [loop-control.md](references/loop-control.md) for details):
- All passes return zero findings → done
- Max 3 full cycles reached → present remaining findings to user
- Stall detected → escalate to user
- Ping-pong detected → present cycle to user with options

### Phase 5: Summary Report

Generate a consolidated report:

```markdown
## Review Summary

**Target**: [files/diff reviewed]
**Iterations**: [N]
**Status**: [Clean / N remaining findings]

### Findings

| # | Pass | Severity | Location | Issue | Status |
|---|------|----------|----------|-------|--------|
| 1 | Direct | HIGH | file:42 | Null pointer dereference | Fixed (iter 1) |
| 2 | Best Practice | MEDIUM | file:78 | Redundant type assertion | Fixed (iter 2) |
| 3 | Critical Think | LOW | file:15 | No rate limiting on endpoint | Acknowledged |

### Iteration History

- **Iteration 1**: 5 findings → 3 fixed
- **Iteration 2**: 2 new findings + 2 remaining → 3 fixed
- **Iteration 3**: 1 remaining (LOW) → acknowledged

### Severity Escalations

- Finding #3 survived 2 iterations: escalated LOW → MEDIUM
```

## Guidelines

### DO

- **Run all 3 passes** — each catches different issue categories
- **Fix and re-verify** — don't just report, iterate until clean
- **Track findings across iterations** — detect stalls and ping-pong early
- **Respect severity levels** — HIGH findings need user approval before fixing
- **Use parallel subagents** — launch all 3 passes simultaneously for speed
- **Report iteration history** — show what was found and fixed in each cycle

### DON'T

- **Skip passes for speed** — thoroughness is the point; use single-pass reviewers for quick checks
- **Auto-fix HIGH severity without approval** — these may have design implications
- **Loop indefinitely** — max 3 full cycles, then escalate
- **Ignore ping-pong** — if findings keep appearing and disappearing, escalate
- **Re-run all passes after trivial fixes** — only re-run affected passes

## Error Handling

| Error | Action |
|-------|--------|
| Subagent times out | Report which pass failed, re-run individually |
| No files to review | Ask user to specify scope |
| Stall detected | Present findings table, ask user: fix manually / accept / abort |
| Ping-pong detected | Show cycle pattern, ask user: accept current state / manual fix / abort |
| External reviewer paste fails | Offer to re-generate prompt or switch to subagent-only mode |

## Reference Files

- [review-passes.md](references/review-passes.md) — Pass specifications, subagent prompt templates, manual paste template
- [loop-control.md](references/loop-control.md) — Iteration limits, exit conditions, stall/ping-pong detection

## Notes

- **Parallel execution**: All 3 passes run as independent subagents in parallel for speed
- **Suggested passes**: 6 optional passes (Testability, Accessibility, API Surface, Performance, i18n, Concurrency) are suggested based on code content signals — not a blind checklist
- **Extensibility**: Users can add fully custom passes beyond the suggested ones; future versions may support MCP tool integration and CLI tool integration (Gemini, Codex, etc.)
- **Privacy**: When using manual paste mode for external AI review, a privacy notice is displayed before generating the prompt — be aware that code content will be shared externally
- **Severity escalation**: Findings surviving 2+ iterations are automatically promoted to the next severity level
- **Scope**: This skill reviews code that exists. For reviewing plans before implementation, use `plan-review` instead
