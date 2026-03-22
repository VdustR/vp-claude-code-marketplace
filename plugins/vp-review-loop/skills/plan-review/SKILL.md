---
name: plan-review
description: >-
  Review, optimize, and score implementation plans with confidence index,
  pros/cons analysis, and auto-fix loop for trivial findings.
  Use when asked to "review this plan", "score this plan",
  "how confident in this plan", "write a plan for X", "design an implementation plan",
  "optimize this plan", "refine this plan", "improve this plan",
  "pros and cons of this approach", "reasons for and against",
  "confidence index", "plan quality",
  or when deciding whether to proceed with an implementation approach before writing code.
  Boundary: for reviewing code already written, use review-loop instead.
---

# Plan Review

Review, optimize, and score implementation plans with a confidence index, structured pros/cons analysis, and auto-fix loop for trivial findings. Three built-in passes evaluate plans from different angles, with context-aware suggested passes for deeper coverage. Trivial and uncontroversial findings are auto-fixed without asking; only HIGH severity or ambiguous findings require user input. A confidence index quantifies readiness to proceed.

## Quick Start

> Review this plan

> Score my implementation plan

> Pros and cons of this approach

> Write a plan for adding auth, then review it

> How confident should I be in this migration plan?

## When to Use

- Evaluating an implementation plan before writing code
- Deciding between multiple approaches with trade-offs
- User wants a confidence score on a proposed plan
- User wants structured pros/cons analysis for a decision
- Optimizing or refining an existing plan
- Writing a plan from scratch with built-in quality review

**When NOT to use**: For reviewing code that's already written, use `review-loop` instead. This skill evaluates *plans* — what you intend to do, not what you've already done.

## Workflow

### Phase 1: Plan Intake

Accept a plan from one of these sources:

| Source | Action |
|--------|--------|
| User provides existing plan | Parse and structure it |
| User describes a goal | Draft a structured plan (Phase 2) |
| Plan file (markdown, text) | Read and parse |
| EnterPlanMode output | Use the plan from plan mode |

If the plan is vague or incomplete, ask clarifying questions before proceeding.

### Phase 2: Plan Drafting (if from goal)

When the user provides a goal instead of a plan, draft one:

1. Research the codebase (read relevant files, understand architecture)
2. Draft a structured plan with:
   - **Objective**: What we're trying to achieve
   - **Steps**: Numbered, actionable steps with file paths
   - **Dependencies**: What must exist before each step
   - **Risks**: Known risks per step
3. Present draft to user for initial feedback
4. Proceed to Phase 3 with the accepted draft

### Phase 3: Plan Review Passes

**Built-in passes** (always run all 3):

| Pass | Focus | What It Catches |
|------|-------|-----------------|
| Feasibility | Can it be done? | Unachievable steps, missing prerequisites, resource gaps, dependency errors |
| Optimality | Is this the best way? | Simpler alternatives, industry patterns, unnecessary complexity, missing quick wins |
| Risk Analysis | What could go wrong? | Hidden assumptions, failure modes, irreversible steps, missing rollback strategies |

See [plan-review-passes.md](references/plan-review-passes.md) for full pass specifications.

**Suggested passes**: After analyzing the plan content, suggest relevant optional passes based on detected signals. See [plan-review-passes.md](references/plan-review-passes.md) for all available suggested passes and their trigger conditions.

| Suggested Pass | Trigger Signals |
|---------------|-----------------|
| Incremental Delivery | 8+ steps, multi-system scope, big-bang deployment strategy |
| Stakeholder Impact | User-facing behavior changes, data migration, cross-team dependencies |
| Maintenance Burden | New infrastructure, external dependencies, custom solutions, ongoing ops work |
| Team Coordination | Multi-codebase changes, shared API contracts, parallel developer work |

Present matching suggestions to the user — they choose which to enable:
- **all**: Enable all suggested passes
- **pick**: User selects specific passes from the suggestions
- **none**: Run only the 3 built-in passes

Suggested passes run in parallel alongside built-in passes and follow the same finding format.

Each pass returns findings:

```
| # | Pass | Severity | Plan Step | Issue | Recommendation |
```

### Phase 4: Auto-Fix Loop

See [loop-control.md](references/loop-control.md) for iteration limits, fix authorization rules, and exit conditions.

**Auto-fix trivial findings** without asking the user:

| Severity | Ambiguity | Action |
|----------|-----------|--------|
| LOW | Any | Auto-fix — revise plan and note in summary |
| MEDIUM | Unambiguous (single clear fix) | Auto-fix — revise plan and note in summary |
| MEDIUM | Ambiguous (multiple valid approaches) | Present to user with options |
| HIGH | Any | Present to user with recommendation |

**After auto-fixing**:
1. Re-run only the passes whose findings were fixed
2. If auto-fixes changed plan structure (steps added/reordered), re-run all 3 passes
3. Repeat until no more auto-fixable findings, or max 3 full cycles reached

**Exit conditions**:
- All passes return zero findings → proceed to Phase 5
- Only HIGH/ambiguous findings remain → proceed to Phase 5 (present these in Phase 7)
- Max 3 cycles reached → proceed to Phase 5 with remaining findings
- Stall detected (same findings persist) → escalate to user

### Phase 5: Confidence Index

Calculate a confidence score using 5 domain-agnostic factors. See [confidence-index.md](references/confidence-index.md) for full specification.

| Factor | Weight | How Measured |
|--------|--------|-------------|
| Step validation | 25% | How many steps have been tested, prototyped, or proven in similar contexts |
| Completeness | 20% | Are all necessary steps, prerequisites, and cleanup steps included |
| Risk coverage | 20% | Are failure modes identified with specific mitigation + rollback strategies |
| Evidence quality | 20% | Are claims backed by docs, tests, prior art, or working prototypes |
| Reversibility | 15% | Can changes be rolled back at every step if things go wrong |

**Thresholds**: 🟢 80%+ (safe to proceed) / 🟡 60-79% (review boost options) / 🔴 <60% (strongly recommend boosting)

**Floor rule**: If ANY single factor scores below 40%, overall indicator is forced to 🔴 regardless of weighted average.

### Phase 6: Pros/Cons Analysis

For each major decision in the plan, generate a structured pros/cons analysis. See [pros-cons-analysis.md](references/pros-cons-analysis.md) for the framework.

Format:

```markdown
### Decision: [What's being decided]

**Reasons FOR**:
- [Pro 1] — [impact level: high/medium/low]
- [Pro 2] — [impact level]

**Reasons AGAINST**:
- [Con 1] — [impact level: high/medium/low]
- [Con 2] — [impact level]

**Recommendation**: [Proceed / Reconsider / Need more info]
```

### Phase 7: User Decision

Present the full assessment and ask the user:

| Option | What Happens |
|--------|-------------|
| **Proceed** | Accept plan as-is, move to implementation |
| **Boost** | Execute specific boost actions to raise confidence, then re-score |
| **Revise** | Agent suggests revisions based on findings; user approves diff before applying |
| **Abort** | Discard plan, start over or abandon |

### Phase 8: Iterate (if revise/boost)

If user chooses **Revise**:
1. Agent suggests specific changes as a diff
2. User reviews and approves changes
3. Re-run affected review passes (not all 3 unless changes are fundamental)
4. Recalculate confidence index
5. Return to Phase 7

If user chooses **Boost**:
1. Execute the selected boost action(s)
2. Re-score the affected confidence factor(s)
3. Recalculate overall confidence
4. Return to Phase 7

**Max iterations**: 3 revise/boost cycles. After 3, present final state and recommend proceeding or aborting.

**Total iteration budget**: Up to 3 auto-fix cycles (Phase 4) + up to 3 user-driven cycles (Phase 8) = 6 cycles maximum across the entire plan review.

## Example Output

```markdown
## Plan Review: Add User Authentication

### Confidence Index: 72% 🟡

| Factor | Score | Reason |
|--------|-------|--------|
| Step validation | 80% | JWT pattern proven in similar projects |
| Completeness | 70% | Missing session cleanup step |
| Risk coverage | 60% | No rollback plan for database migration |
| Evidence quality | 75% | Official docs referenced, no prototype |
| Reversibility | 65% | DB migration is one-way |

### Review Findings

| # | Pass | Severity | Step | Issue | Recommendation |
|---|------|----------|------|-------|----------------|
| 1 | Feasibility | HIGH | 3 | DB migration requires downtime | Add zero-downtime migration strategy |
| 2 | Optimality | MEDIUM | 5 | Custom session store — use Redis instead | Switch to Redis session store |
| 3 | Risk Analysis | HIGH | 3 | No rollback plan for schema change | Add reversible migration script |

### Pros/Cons: JWT vs Session-Based Auth

**Reasons FOR JWT**:
- Stateless, scales horizontally — high
- No server-side storage needed — medium

**Reasons AGAINST JWT**:
- Cannot revoke individual tokens — high
- Token size larger than session ID — low

**Recommendation**: Proceed with JWT + short expiry + refresh token rotation

### To increase confidence:

- [ ] **+8%** Add reversible DB migration script (Risk coverage, Reversibility)
- [ ] **+5%** Add session cleanup cron job (Completeness)
- [ ] **+4%** Prototype JWT middleware in /tmp (Step validation)
- [ ] **+3%** Test refresh token rotation flow (Evidence quality)

Proceed with current confidence, or boost first? [proceed / boost / revise / abort]
```

## Guidelines

### DO

- **Run all 3 passes** — feasibility, optimality, and risk catch different issues
- **Auto-fix trivial findings** — LOW and unambiguous MEDIUM findings should be fixed without asking
- **Show confidence breakdown** — factor-level scores help users understand weaknesses
- **Provide actionable boosts** — each boost option must be concrete and executable
- **Get approval for HIGH/ambiguous findings** — these involve strategic choices
- **Structure pros/cons per decision** — not one big list for the whole plan
- **Track auto-fix history** — show what was auto-fixed in the iteration summary

### DON'T

- **Ask for trivial fixes** — auto-fix LOW/unambiguous MEDIUM findings, don't interrupt the user
- **Auto-fix strategic decisions** — HIGH severity or ambiguous findings need user input
- **Skip confidence index** — it's the core value proposition
- **Give vague boost options** — "do more research" is not actionable
- **Loop indefinitely** — max 3 full auto-fix cycles, then escalate
- **Conflate code review with plan review** — plans are about approach, not syntax

## Error Handling

| Error | Action |
|-------|--------|
| Plan is too vague to review | Ask user for specifics: scope, constraints, target |
| No measurable steps in plan | Restructure into numbered actionable steps, confirm with user |
| Confidence index is 🔴 | Strongly recommend boosting; list top 3 boost options by impact |
| All passes return zero findings | Confirm plan is solid; still calculate confidence index |
| User provides both code and plan | Ask which to review; suggest review-loop for code |

## Reference Files

- [plan-review-passes.md](references/plan-review-passes.md) — Feasibility, Optimality, Risk Analysis pass specifications
- [confidence-index.md](references/confidence-index.md) — Generalized confidence index with 5 factors
- [pros-cons-analysis.md](references/pros-cons-analysis.md) — Structured pros/cons framework
- [loop-control.md](references/loop-control.md) — Auto-fix authorization, iteration limits, exit conditions

## Notes

- **Auto-fix loop**: Trivial findings (LOW, unambiguous MEDIUM) are auto-fixed without asking. Only HIGH or ambiguous findings require user input. This makes plan review faster and less interruptive.
- **Plan mode integration**: Works with Claude Code's `EnterPlanMode` — can review plans generated in plan mode
- **Iterative refinement**: The auto-fix → re-review loop is capped at 3 cycles to prevent diminishing returns. User-driven revise/boost cycles add up to 3 more.
- **Suggested passes**: 4 optional passes (Incremental Delivery, Stakeholder Impact, Maintenance Burden, Team Coordination) are suggested based on plan content signals
- **Domain-agnostic**: Confidence factors are designed for any implementation plan, not specific to dependencies or migrations
- **Confidence re-calculation**: Confidence index is recalculated after each auto-fix cycle, giving continuous feedback on plan quality improvement
- **Scope**: This skill reviews plans. For reviewing code already written, use `review-loop` instead
