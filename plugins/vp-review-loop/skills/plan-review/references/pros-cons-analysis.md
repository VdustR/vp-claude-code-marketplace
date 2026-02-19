# Pros/Cons Analysis Framework

## Purpose

Provide structured reasoning for each major decision in a plan. Each decision gets an independent pros/cons analysis to help the user make informed choices.

## When to Generate

Generate a pros/cons analysis for:
- Technology or library choices (e.g., JWT vs session-based auth)
- Architecture decisions (e.g., monolith vs microservices)
- Strategy choices (e.g., incremental migration vs big bang)
- Trade-off decisions (e.g., performance vs maintainability)
- Scope decisions (e.g., MVP vs full feature set)

Do NOT generate for:
- Implementation details with only one reasonable approach
- Steps that are prerequisites with no alternatives
- Decisions already made and irreversible

## Output Format

```markdown
### Decision: [What's being decided]

**Context**: [Brief description of why this decision matters]

**Reasons FOR (做的理由)**:
- [Pro 1] — [impact: high/medium/low]
- [Pro 2] — [impact: high/medium/low]
- [Pro 3] — [impact: high/medium/low]

**Reasons AGAINST (不做的理由)**:
- [Con 1] — [impact: high/medium/low]
- [Con 2] — [impact: high/medium/low]
- [Con 3] — [impact: high/medium/low]

**Recommendation**: [Proceed / Reconsider / Need more info]
**Confidence**: [How confident in this recommendation: high/medium/low]
```

## Impact Levels

| Level | Meaning |
|-------|---------|
| **high** | Significantly affects project success, timeline, or maintainability |
| **medium** | Noticeable effect on developer experience or specific feature areas |
| **low** | Minor effect, mostly about preference or marginal improvement |

## Quality Criteria

Each pro/con must be:
- **Specific**: Not "it's faster" but "reduces API response time by ~200ms due to fewer DB queries"
- **Evidenced**: Reference docs, benchmarks, or prior experience when possible
- **Relevant**: Directly affects the current project, not theoretical
- **Distinct**: Each item covers a different aspect — no padding with variations of the same point

## Handling Asymmetric Decisions

When pros heavily outweigh cons (or vice versa):
- Still list at least 2 items on each side
- Acknowledge the asymmetry explicitly: "The cons are minor compared to the benefits"
- This prevents rubber-stamping — even clear decisions benefit from documented trade-offs

## Multiple Alternatives

When more than 2 options exist, use a comparison table:

```markdown
### Decision: [What's being decided]

| Criterion | Option A | Option B | Option C |
|-----------|----------|----------|----------|
| [Factor 1] | [Assessment] | [Assessment] | [Assessment] |
| [Factor 2] | [Assessment] | [Assessment] | [Assessment] |
| [Factor 3] | [Assessment] | [Assessment] | [Assessment] |

**Recommendation**: Option B — [brief justification]
```

Then follow with full pros/cons for the recommended option vs the strongest alternative.
