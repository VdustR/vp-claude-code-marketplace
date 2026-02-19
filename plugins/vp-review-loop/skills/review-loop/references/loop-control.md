# Loop Control Specification

## Iteration Limits

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Max full cycles | 3 | Diminishing returns after 3 iterations |
| Max accumulated unique findings | 10 | Beyond this, issues are systemic — escalate to user |
| Max findings per pass per iteration | 20 | Truncate to most severe; likely a larger problem |

A **full cycle** = run all applicable passes + fix findings. Partial re-runs (only affected passes) count as part of the current cycle, not a new one.

## Re-run Rules

After fixes are applied, determine which passes to re-run:

| Condition | Action |
|-----------|--------|
| Direct findings fixed | Re-run Direct |
| Best Practice findings fixed | Re-run Best Practice |
| HIGH severity findings fixed (any pass) | Re-run Critical Think |
| Best Practice fixes touch security-sensitive regions | Re-run Critical Think |
| Only LOW findings fixed | Re-run only the originating pass |

**Security-sensitive regions** (trigger Critical Think re-run):
- Authentication/authorization logic
- Cryptographic operations
- Input validation and sanitization
- Database queries and ORM calls
- File system operations with user-controlled paths
- Network requests with user-controlled URLs

## Exit Conditions

### Clean Exit
All passes return zero findings. Report success with iteration history.

### Max Iterations
3 full cycles completed with remaining findings. Present final findings table to user with options:
- **Accept**: Acknowledge remaining findings, proceed
- **Manual fix**: User fixes remaining issues themselves
- **Abort**: Discard all changes

### Stall Detection

**Trigger**: Same findings persist across 2 consecutive iterations (found → "fixed" → found again) OR accumulated unique findings across all iterations exceed 10.

**Response**:
1. Present stall findings table
2. Flag as systemic: "These findings suggest a deeper structural issue"
3. Ask user: fix manually / accept / abort

### Ping-Pong Detection

**Definition**: Finding appears in iteration N, disappears in N+1, reappears in N+2 (or later). This indicates a fix for one issue re-introduces another.

**Detection method**: Track ALL findings across ALL iterations using the finding comparison key (`pass + severity + location key`). If a finding's location key appeared in a previous non-consecutive iteration, flag as ping-pong.

**Response**:
1. Show the cycle pattern:
   ```
   Ping-pong detected:
   - Iter 1: Finding at file:42 (null check added)
   - Iter 2: Finding at file:42 resolved
   - Iter 3: Finding at file:42 reappeared (null check conflicts with new logic)
   ```
2. Ask user: accept current state / manual fix / abort

**3-step cycles**: If finding appears in iterations 1, 3, and would appear in 5, this falls through to stall detection (accumulated findings > 10) before reaching 3 full cycles. No special handling needed.

## Severity Escalation

Findings surviving 2+ iterations are automatically promoted:

| Original | After 2 iterations | Rationale |
|----------|-------------------|-----------|
| LOW | MEDIUM | Persistent issues deserve attention |
| MEDIUM | HIGH | Resisting fixes indicates deeper problem |
| HIGH | HIGH (flagged) | Already highest; flag as "resistant" |

Escalated findings are marked in the summary report:
```
| # | Pass | Severity | Location | Issue | Status |
| 3 | Direct | MEDIUM→HIGH | file:42 | Null safety gap | Escalated (survived 2 iter) |
```

## Fix Authorization

| Severity | Complexity | Action |
|----------|-----------|--------|
| LOW | Any | Auto-fix |
| MEDIUM | Simple (≤5 lines, same function) | Auto-fix |
| MEDIUM | Complex (>5 lines or crosses function) | Ask user |
| HIGH | Any | Ask user |
| Any | Crosses API boundary | Ask user |

**"Ambiguous" definition**: A fix is ambiguous when any of these apply:
- Spans more than 5 lines of changes
- Crosses function or method boundaries
- Involves API interface changes (function signatures, exported types)
- Multiple valid fix approaches exist
- Fix would change observable behavior (not just internal refactoring)

## Finding Tracking

Maintain a running ledger across all iterations:

```
Iteration 1:
  [D-HIGH-file:42] Null pointer dereference → FIXED
  [B-MED-file:78]  Redundant type assertion → FIXED
  [C-LOW-file:15]  No rate limiting        → DEFERRED

Iteration 2:
  [D-MED-file:42]  New: Missing error check (from null fix) → FIXED
  [C-LOW-file:15]  Carried: No rate limiting → ESCALATED to MEDIUM

Iteration 3:
  [C-MED-file:15]  Carried: No rate limiting → PRESENTED TO USER
```

Legend: `[Pass-Severity-Location]` where D=Direct, B=Best Practice, C=Critical Think
