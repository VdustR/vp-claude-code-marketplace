# Confidence Index Specification

## Factor Weights

| Factor | Weight | How Measured |
|--------|--------|-------------|
| Step validation | 25% | How many steps have been tested, prototyped, or proven in similar contexts |
| Completeness | 20% | Are all necessary steps, prerequisites, and cleanup steps included |
| Risk coverage | 20% | Are failure modes identified with specific mitigation + rollback strategies |
| Evidence quality | 20% | Are claims backed by docs, tests, prior art, or working prototypes |
| Reversibility | 15% | Can changes be rolled back at every step if things go wrong |

## Thresholds

| Level | Range | Meaning |
|-------|-------|---------|
| 🟢 High | 80%+ | Safe to proceed |
| 🟡 Medium | 60-79% | Review boost options before proceeding |
| 🔴 Low | <60% | Strongly recommend boosting before proceeding |

**Floor rule**: If ANY single factor scores below 40%, overall indicator is forced to 🔴 regardless of weighted average.

## Scoring Guidelines

### Step Validation (25%)

- **100%**: Every step has been tested, prototyped, or proven in a similar project
- **80%**: Most steps are proven; a few are based on reliable documentation
- **60%**: Core steps are proven; some steps rely on untested assumptions
- **40%**: Some steps tested; significant portions are theoretical
- **<40%**: No steps have been validated — plan is entirely speculative

### Completeness (20%)

- **100%**: All steps, prerequisites, cleanup, error handling, and edge cases covered
- **80%**: Main flow complete; minor gaps in cleanup or edge case handling
- **60%**: Core steps present; missing some prerequisites or cleanup steps
- **40%**: Significant gaps — missing steps that would cause the plan to stall
- **<40%**: Plan is an outline, not an executable plan

### Risk Coverage (20%)

- **100%**: Every step has identified failure modes with specific mitigation + rollback
- **80%**: Most steps have risk coverage; a few have generic "handle errors" notes
- **60%**: Known risks covered; some steps have no failure analysis
- **40%**: Only obvious risks addressed; no systematic risk analysis
- **<40%**: No risk analysis performed

### Evidence Quality (20%)

- **100%**: All claims backed by working prototypes, test results, or official docs
- **80%**: Most claims backed by documentation or prior art; a few by experience
- **60%**: Core approach backed by docs; some steps rely on blog posts or assumptions
- **40%**: Limited evidence; mostly based on general knowledge
- **<40%**: No evidence cited — plan based entirely on assumptions

### Reversibility (15%)

- **100%**: Every step can be independently rolled back without data loss
- **80%**: Most steps reversible; a few require careful ordering to undo
- **60%**: Core steps reversible; some steps (e.g., data migration) are one-way
- **40%**: Several irreversible steps without documented rollback strategy
- **<40%**: Multiple irreversible steps with no rollback plan — high commitment risk

## Example Output

### Confidence Index: 72% 🟡

| Factor | Score | Reason |
|--------|-------|--------|
| Step validation | 80% | JWT pattern proven in similar projects |
| Completeness | 70% | Missing session cleanup step |
| Risk coverage | 60% | No rollback plan for database migration |
| Evidence quality | 75% | Official docs referenced, no prototype |
| Reversibility | 65% | DB migration is one-way |

### To increase confidence:

- [ ] **+8%** Add reversible DB migration script (Risk coverage ↑, Reversibility ↑)
- [ ] **+5%** Add session cleanup cron job (Completeness ↑)
- [ ] **+4%** Prototype JWT middleware in /tmp (Step validation ↑)
- [ ] **+3%** Test refresh token rotation flow (Evidence quality ↑)

Proceed with current confidence, or boost first? [proceed / boost / revise / abort]

## Boost Options

Each boost option includes:
- **Estimated % improvement** — how much it raises the overall confidence index
- **Which factor(s) it improves** — direct mapping to factor weights
- **Concrete action** — specific, executable step (not vague "do more research")
- **Time/effort estimate** — relative: quick (minutes), moderate (hours), significant (days)

Always let user choose: proceed at current confidence, boost specific factors, revise plan, or abort.

## Recalculation After Boost

When a boost action is completed:
1. Re-score only the affected factor(s)
2. Recalculate weighted average
3. Re-check floor rule
4. Present updated confidence index
5. Return to user decision point
