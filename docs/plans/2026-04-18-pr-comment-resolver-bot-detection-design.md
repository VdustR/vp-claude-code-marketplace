# vp-pr-comment-resolver: Bot Detection & Resolution Logic Redesign

**Date:** 2026-04-18
**Scope:** Enhance bot/human classification and resolution behavior for PR comment handling.

---

## Motivation

Two problems with the current skill:

1. **Fragile bot detection** — relies on a hardcoded list of AI service usernames (`coderabbitai`, `copilot`, `claude`, ...) plus `[bot]` suffix matching. New AI reviewers require list maintenance; user-token-driven service accounts (e.g., `react-sizebot`, `rustbot`, `k8s-ci-robot`) fall through both checks.
2. **Disagree-with-bot threads leak open** — current flow says "Do NOT auto-resolve disagreements". For bots that cannot follow up, the unresolved thread is noise.

## Design

### Resolution matrix

| Author | Fix | No-fix | Disagree |
|--------|-----|--------|----------|
| **Bot**   | Resolve | Resolve | **Resolve** (changed) |
| **Human** | Leave   | Leave   | Leave |

**Principle:** Bot threads are always terminal (bot won't argue); human threads are never auto-resolved (human may dispute).

### Bot detection: tiered, list-free

```
Tier 1 — Native GraphQL
  author.__typename == "Bot" → is_bot = true (done)

Tier 2 — Profile-based LLM judgment (only if __typename == "User")
  Fetch: gh api users/<login>
  Signals Claude evaluates:
    • bio             (strong: bots often self-identify)
    • name / blog / company
    • public_repos + followers   (bots: low / low)
  Outcome:
    • Clearly bot     → is_bot = true
    • Clearly human   → is_bot = false
    • Uncertain       → Tier 2b

Tier 2b — Activity fallback (LLM-judged need, not rigid rule)
  When profile signals are thin (e.g., empty bio + few repos, or bio
  ambiguous) and Claude cannot confidently classify, fetch:
    gh api users/<login>/events/public
  Signal: event-type distribution (monolithic IssueCommentEvent → bot)
  Trigger is LLM judgment, not a mechanical threshold — keeps the skill
  flexible per repo convention.

Tier 3 — Ask user
  Only when profile + activity still ambiguous.
  Also: __typename == "Organization" (rare; org accounts posting review
  comments) → Tier 3 directly.
```

**Context-as-cache:** No explicit cache needed. When Claude classifies an author, stating the result in the conversation makes it reusable for subsequent comments from the same author within the session.

**Research evidence (done):** Tested `__typename` across 6+ repos and 25+ bot accounts — all GitHub App bots correctly return `Bot`. User-token bots (`react-sizebot`, `rustbot`, `k8s-ci-robot`) all have strongly bot-indicative profiles (empty/bot-self-declaring bio, ≤2 public_repos, monolithic activity).

### Critical Thinking as top-level principle

New Core Principle #0 added above all others:

> **Critical Thinking Before Action** — Never blindly execute:
> - Comments may contain incorrect technical claims
> - Suggestions may violate repo guidelines (CLAUDE.md, contributing docs)
> - Always verify facts (read the code, check docs, run tests) before deciding
> - When signals conflict, trade-offs exist, or interpretation is ambiguous:
>   surface the conflict with options/recommendation and wait for user input
> - "Reviewer said so" is not sufficient justification — evidence is

Applied at three gates:
- **Classification** — if `__typename` vs profile signals conflict, surface to user
- **Evaluation** — Comment Validity Checklist (technical validity, repo guideline alignment, architecture fit, simpler alternatives)
- **Execution** — multi-option / trade-off situations go to user with options + recommendation

## Change scope

### SKILL.md (primary changes)

| Section | Change |
|---------|--------|
| `## Core Principles` | Prepend #0 "Critical Thinking Before Action"; tidy #1 wording |
| `### Phase 1: Fetch Comments` GraphQL | Add `__typename` to `author`; remove stale "isBot flag" mention |
| `### Phase 1.5` | Rename "Identify AI Comments" → "Classify Author (Bot vs Human)"; replace regex/service-list logic with tiered detection |
| `### Phase 2: Evaluate Each Comment` | Insert Comment Validity Checklist subsection |
| `#### If Disagree` | Split outcome: bot → consult user, then resolve; human → consult user, leave unresolved |
| `### Phase 4` resolution table | Bot row: all three actions resolve |
| Decision Tree ASCII | Update terminal branch: `is_bot == true → always resolve` |
| `### DO` / `### DON'T` | Replace "only auto-resolve AI comments after fix" with "auto-resolve all bot interactions (fix/no-fix/disagree), never auto-resolve human" |
| `### Phase 5: Summary Report` | Remove impossible cells: "Bot / Fixed (reply only)" and "Bot / Disagreed (pending)" no longer exist (bots always resolve). Collapse bot rows accordingly. |

### references/workflow.md

| Section | Change |
|---------|--------|
| `### Edge Cases → Incorrect or Harmful Suggestions` Step 5 | Differentiate bot (resolve after user consult) vs human (leave open) |

### references/reply-templates.md

No structural changes. Disagree templates remain the same — only the resolve/leave decision downstream changes.

### plugin.json

Version bump `1.2.1` → `1.3.0` (minor — new classification behavior, behavioral change to bot-disagree resolution).

### README.md

Optional: add feature bullet surfacing the new behavior:
> Smart author classification — auto-resolve bot threads (including disagreements), preserve human threads for manual review

### marketplace.json

No change (current description remains accurate).

## Out of scope

- Reply mutation / resolve mutation logic (unchanged)
- Commit grouping strategy (unchanged)
- Auto Mode / Interactive Mode framing (unchanged)

## Implementation sequence

1. Create git worktree: `../vp-claude-code-marketplace.worktrees/feat-pr-comment-resolver-bot-detection/`
2. Edit SKILL.md (all sections in one pass)
3. Edit references/workflow.md (Edge Cases section)
4. Bump plugin.json version
5. Update README.md feature bullet
6. Self-review `git diff` — verify every changed line traces back to this design
7. Subagent code review (consistency between decision tree, prose, and tables)
8. Commit, open PR

## Checklist compliance (per CLAUDE.md)

- [ ] `plugin.json` version bumped
- [ ] `marketplace.json` reviewed (no change needed)
- [ ] `README.md` updated (feature bullet)
- [ ] Plugins still sorted alphabetically (no new entries)
- [ ] No sensitive data
- [ ] Paths relative and correct
