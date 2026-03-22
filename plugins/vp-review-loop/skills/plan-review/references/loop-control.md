# Plan Review Loop Control Specification

## Iteration Limits

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Max full cycles | 3 | Diminishing returns after 3 iterations |
| Max accumulated unique findings | 10 | Beyond this, issues are systemic — escalate to user |
| Max findings per pass per iteration | 15 | Truncate to most severe; likely a structural problem |

A **full cycle** = run all applicable passes + auto-fix eligible findings + present remaining to user. Partial re-runs (only affected passes) count as part of the current cycle, not a new one.

## Fix Authorization

Plan-review auto-fixes trivial, uncontroversial findings without asking. "Fix" in plan context means revising the plan text (adding steps, reordering, filling gaps, correcting dependencies).

| Severity | Ambiguity | Action |
|----------|-----------|--------|
| LOW | Any | Auto-fix — apply and note in summary |
| MEDIUM | Unambiguous (single clear fix) | Auto-fix — apply and note in summary |
| MEDIUM | Ambiguous (multiple valid approaches) | Ask user — present options |
| HIGH | Any | Ask user — present finding + recommendation |

**"Unambiguous" definition for plan fixes**: A fix is unambiguous when ALL of these apply:
- Only one reasonable way to address the finding
- Does not change the plan's strategic direction or core approach
- Does not add/remove major steps (minor additions like cleanup steps are OK)
- Does not affect the plan's scope, timeline, or resource requirements

**"Ambiguous" definition**: A fix is ambiguous when ANY of these apply:
- Multiple valid approaches exist (e.g., "use Redis vs Memcached for caching")
- Changes the plan's overall strategy or architecture
- Adds or removes major steps
- Involves trade-offs the user should weigh (e.g., speed vs reliability)
- Affects cross-team coordination or stakeholder commitments

## Auto-Fix Examples

| Finding | Severity | Auto-fix? | Fix Applied |
|---------|----------|-----------|-------------|
| "Step 3 depends on step 5 output but runs before it" | MEDIUM | Yes | Reorder steps 3 and 5 |
| "Missing cleanup step after database migration" | LOW | Yes | Add cleanup step after migration |
| "Step 2 is too vague: 'optimize the system'" | LOW | Yes | Expand to specific sub-steps based on context |
| "No rollback plan for schema change" | HIGH | No | Present to user with recommended rollback strategy |
| "Custom solution vs established library" | MEDIUM | No (ambiguous) | Present trade-offs to user |
| "Missing prerequisite: API key not provisioned" | LOW | Yes | Add prerequisite step |

## Re-run Rules

After auto-fixes are applied, determine which passes to re-run:

| Condition | Action |
|-----------|--------|
| Feasibility findings fixed (step ordering, prerequisites) | Re-run Feasibility |
| Optimality findings fixed (step restructuring) | Re-run Optimality |
| Risk findings fixed (rollback plans added, mitigation added) | Re-run Risk Analysis |
| Auto-fixes changed plan structure (steps added/reordered) | Re-run all 3 passes |
| Only LOW findings fixed with no structural change | Re-run only the originating pass |

## Exit Conditions

### Clean Exit
All passes return zero findings. Report success with iteration history.

### Auto-Fix Complete
All remaining findings after auto-fix are HIGH or ambiguous MEDIUM. Present these to user for decision (Phase 6).

### Max Iterations
3 full cycles completed with remaining findings. Present final findings table to user with options:
- **Accept**: Acknowledge remaining findings, proceed with current plan
- **Manual revise**: User revises remaining issues themselves
- **Abort**: Discard revised plan, revert to original

### Stall Detection

**Trigger**: Same findings persist across 2 consecutive iterations (found → "fixed" → found again) OR accumulated unique findings across all iterations exceed 10.

**Response**:
1. Present stall findings table
2. Flag as systemic: "These findings suggest a fundamental plan design issue"
3. Ask user: revise manually / accept / abort

## Confidence Index Re-calculation

After each auto-fix cycle, recalculate the confidence index:
1. Re-score only the factors affected by the fixes
2. Recalculate weighted average
3. Re-check floor rule
4. Present updated confidence alongside the iteration summary

This gives the user a clear signal of whether auto-fixes are improving plan quality.

## Finding Tracking

Maintain a running ledger across all iterations:

```
Iteration 1:
  [F-MED-step3] Dependency ordering wrong    → AUTO-FIXED (reordered steps)
  [O-LOW-step5] Missing parallelism opportunity → AUTO-FIXED (marked as parallel)
  [R-HIGH-step2] No rollback for DB migration → PRESENTED TO USER

Iteration 2 (after user addresses HIGH finding):
  [R-MED-step2] Rollback plan incomplete      → AUTO-FIXED (added verification step)
  [F-LOW-step7] Missing cleanup step           → AUTO-FIXED (added cleanup)

Iteration 3:
  All passes clean → DONE
```

Legend: `[Pass-Severity-StepN]` where F=Feasibility, O=Optimality, R=Risk
