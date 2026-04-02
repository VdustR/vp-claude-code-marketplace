# vp-retro Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a session retrospective plugin that helps users discover improvement opportunities through interactive dialogue after a Claude Code session.

**Architecture:** Single skill (retro) with references/ for subagent dimension guides. Main skill does open-ended observation from conversation context, presents findings with initial recommendations, then lets user choose which to deep-dive via subagents. Each subagent follows a full cycle: research → analyze → design solutions → present options (with descriptions, differences, examples, recommendations).

**Tech Stack:** Pure SKILL.md + references/ markdown. No scripts, no hooks, no state files.

---

### Task 1: Create Plugin Structure

**Files:**
- Create: `plugins/vp-retro/.claude-plugin/plugin.json`
- Create: `plugins/vp-retro/skills/retro/SKILL.md`
- Create: `plugins/vp-retro/skills/retro/references/dimensions.md`
- Create: `plugins/vp-retro/skills/retro/references/subagent-guide.md`

**Step 1: Create directories**

```bash
mkdir -p plugins/vp-retro/.claude-plugin
mkdir -p plugins/vp-retro/skills/retro/references
```

**Step 2: Create plugin.json**

```json
{
  "name": "vp-retro",
  "version": "1.0.0",
  "description": "Session retrospective — discover improvement opportunities through interactive dialogue after a Claude Code session",
  "author": {
    "name": "VdustR",
    "url": "https://github.com/VdustR"
  },
  "homepage": "https://github.com/VdustR/vp-claude-code-marketplace",
  "repository": "https://github.com/VdustR/vp-claude-code-marketplace",
  "license": "MIT",
  "keywords": ["retro", "retrospective", "session-review", "improvement", "workflow", "optimization"],
  "skills": "./skills/"
}
```

**Step 3: Commit**

```bash
git add plugins/vp-retro/.claude-plugin/plugin.json
git commit -m "feat: scaffold plugin structure"
```

---

### Task 2: Write Main SKILL.md

**File:** `plugins/vp-retro/skills/retro/SKILL.md`

**Design Principles (from brainstorm):**
- SKILL.md is guidance, not a rigid flowchart — tell AI "what" and "why", not every step of "how"
- Keep maximum flexibility for AI to adapt to actual session content
- Interactive, not fully automated — design questions to converge with user
- Report → Dialogue model: observe first, then guide user to choose depth

**Content outline for SKILL.md:**

```
Frontmatter:
  name: retro
  description: >-
    Session retrospective — review a Claude Code session to discover improvement
    opportunities through interactive dialogue.
    Use when asked to "retro", "session review", "review this session",
    "what can I improve", "session retrospective",
    or at the end of a work session to reflect on what happened.
    Boundary: not for code review (use review-loop), not for PR review
    (use pr-review-toolkit).

# Session Retro

One-paragraph summary of what this does and the philosophy.

## Quick Start
  Natural language examples

## When to Use
  Bullet list

## How It Works

  Describe the typical flow as guidance, NOT a rigid sequence.
  The AI should adapt to the conversation naturally.
  Write each section as 2-3 sentences of intent, not step-by-step procedures.

  ### Observation
  - Review the session conversation context
  - Freely identify anything noteworthy (not constrained by categories)
  - Use the 15 dimensions in [dimensions.md](references/dimensions.md) as a
    checklist to catch things the open-ended scan might miss
  - For each observation: one-line finding + initial actionable recommendation

  ### Interactive Deep-Dive
  - Present observations one at a time with progress indicator
  - For each: ask user if they want to deep-dive
  - User can also add observations AI missed
  - All subagent usage requires user's permission
  - When spawning subagents, spawn confirmed selections in parallel
  - See [subagent-guide.md](references/subagent-guide.md) for subagent behavior

  ### Results & Discussion
  - Present each subagent's result one at a time
  - Each result includes: analysis, solution options
    (with descriptions, differences, examples, recommendations)
  - User can discuss, ask questions, or move to next

  ### Action Planning
  - After all results discussed, compile an action plan
  - Ask user if they want subagent review of the plan
  - For each action, present execution options based on target:
    - This repo: direct edit / worktree / append to PR / new PR / issue / .md note
    - Other repo: issue / fork+PR / .md note / skip
    - Personal config: direct edit / .md note / skip
  - Each option with description, differences, recommendation + reasoning

## Guidelines
  DO / DON'T list

## Reference Files
  - [dimensions.md](references/dimensions.md) — 15 analysis dimensions checklist
  - [subagent-guide.md](references/subagent-guide.md) — Subagent deep-dive behavior guide

## Notes
  Edge cases, limitations
```

**Key principle: keep the SKILL.md concise.** The sections above are guidance for the AI's approach, not a fixed pipeline. The AI should adapt the flow naturally based on the conversation. Write each section as brief intent (2-3 sentences), not exhaustive step-by-step procedures.

**Step 1: Write SKILL.md**

Write the full content following the outline above. Target ~150-200 lines max.

**Step 2: Commit**

```bash
git add plugins/vp-retro/skills/retro/SKILL.md
git commit -m "feat: write main retro skill"
```

---

### Task 3: Write references/dimensions.md

**File:** `plugins/vp-retro/skills/retro/references/dimensions.md`

This is the checklist of 15 analysis dimensions used as a safety net after the open-ended scan. Each dimension gets:
- Name
- One-sentence description
- What signal to look for

**The 15 dimensions:**

| # | Name | What to look for |
|---|------|-----------------|
| 1 | correction-analyzer | User corrected AI's output — naming, pattern, approach |
| 2 | practice-discoverer | AI followed a good practice not documented anywhere |
| 3 | decision-path-analyzer | Key decisions made, alternatives considered, paths abandoned |
| 4 | efficiency-auditor | Repeated operations, unnecessary file re-reads, wasted back-and-forth, cognitive overload |
| 5 | prompt-coach | Vague prompts causing confusion, missing context, could-have-been-one-message |
| 6 | risk-reviewer | Near-miss risky operations (force push, secret exposure, skipping hooks) |
| 7 | git-hygiene-reviewer | Commit message quality, branch management, PR practices |
| 8 | skill-auditor | Skills used — quality, trigger accuracy, community alternatives, ownership |
| 9 | hook-effectiveness-auditor | Hooks that fired, blocked, or should-have-fired-but-didn't |
| 10 | orchestration-auditor | Context window usage, subagent effectiveness, tool choice |
| 11 | env-friction-detector | MCP timeouts, missing tools, version issues, permission errors |
| 12 | upstream-issue-tracker | Third-party bugs, doc-vs-reality mismatches, external blockers |
| 13 | flow-designer | Repeated manual patterns that could become a skill or workflow |
| 14 | knowledge-auditor | Memory health, stale docs, missing handoff context |
| 15 | cross-session-pattern | Recurring issues across sessions (optional — only if user wants to review multiple sessions) |

**Format guidance:** Keep this file as a clean reference table. Don't over-describe — the AI uses these as prompts to look for signals, not as rigid detection rules.

**Step 1: Write dimensions.md**

**Step 2: Commit**

```bash
git add plugins/vp-retro/skills/retro/references/dimensions.md
git commit -m "feat: add 15 analysis dimensions reference"
```

---

### Task 4: Write references/subagent-guide.md

**File:** `plugins/vp-retro/skills/retro/references/subagent-guide.md`

This defines how subagents should behave when deep-diving an observation. Two parts:
1. **Universal behavior** — the research→present cycle and action target options (applies to all)
2. **Dimension-specific guidance** — clearly labeled per-dimension logic (only applies when relevant)

**Content outline:**

```
# Subagent Deep-Dive Guide

## Universal: Research → Analyze → Design → Present

Every deep-dive follows this cycle:

1. Research: Investigate the observation
   - Scan relevant files, conventions, docs
   - Check if repo has existing rules/patterns
   - Search community for related skills/tools if relevant

2. Analyze: Identify root cause and context
   - Why did this happen?
   - Is this repo-specific or personal preference?
   - Is there existing documentation that was missed or unclear?

3. Design solutions: Propose concrete options
   - Each option must be actionable (not "consider doing X")

4. Present to user: Use standard option format
   - Options with: description, differences, examples, recommendation + reasoning
   - Always include a "skip / do nothing" option

## Universal: Action Target Options
Present execution options based on where the action targets:

This repo:
- Direct edit (current working tree)
- Use worktree (isolated)
- Append to existing PR / changes
- New PR
- File issue
- Save as .md note

Other repo:
- File issue
- Fork + PR
- Save as .md note
- Skip

Personal config (~/.claude/):
- Direct edit
- Save as .md note
- Skip

## Dimension-Specific: Correction Analysis Chain
(Applies to correction-analyzer and practice-discoverer)

When analyzing a correction:
- Determine type (naming, architecture, tooling, flow...)
- Check repo: does a consistent convention exist?
  - Yes + documented → Why wasn't it followed? (unclear desc, not triggered, no examples)
  - Yes + not documented → Suggest where to document (repo CLAUDE.md, .claude/rules/, skill)
  - No convention → Suggest establishing one (repo vs personal)
- Same chain for positive discoveries (practice-discoverer):
  done right but not documented → suggest codifying

## Dimension-Specific: Skill Ownership Detection
(Applies to skill-auditor)

- Check if skill path is under user's own marketplace or personal skills
- Check plugin.json author field
- If self-maintained → suggest direct improvements
- If community-maintained → suggest issue, PR, or alternative
```

**Keep it brief.** This is a reference the AI reads once, not a step-by-step manual.

**Step 1: Write subagent-guide.md**

**Step 2: Commit**

```bash
git add plugins/vp-retro/skills/retro/references/subagent-guide.md
git commit -m "feat: add subagent deep-dive guide"
```

---

### Task 5: Register in Marketplace

**Files:**
- Modify: `.claude-plugin/marketplace.json` (add vp-retro entry, alphabetically sorted)
- Modify: `README.md` (add vp-retro section, alphabetically sorted)

**Step 1: Add to marketplace.json**

Add in alphabetical position:
```json
{
  "name": "vp-retro",
  "source": "./plugins/vp-retro",
  "description": "Session retrospective — discover improvement opportunities through interactive dialogue",
  "license": "MIT",
  "keywords": ["retro", "retrospective", "session-review", "improvement", "workflow"]
}
```

**Step 2: Add to README.md**

Add in alphabetical position among existing plugins:
```markdown
### vp-retro

Session retrospective — discover improvement opportunities through interactive dialogue after a Claude Code session.

\`\`\`bash
/plugin install vp-retro@vdustr
\`\`\`

Features:
- Open-ended session observation with 15-dimension safety net
- Interactive deep-dive with parallel subagent research
- Full analysis cycle: research → analyze → design solutions → present options
- Action planning with context-aware execution options (edit / PR / issue / worktree)
```

**Step 3: Commit**

```bash
git add .claude-plugin/marketplace.json README.md
git commit -m "feat: register in marketplace"
```

---

### Task 6: Review & Test

**Step 1: Self-review all files**

Run review-loop on the new plugin:
```
Review plugins/vp-retro/
```

Check:
- [ ] plugin.json has all required fields
- [ ] SKILL.md frontmatter is valid
- [ ] SKILL.md is concise (~150-200 lines, not a rigid flowchart)
- [ ] SKILL.md description is "pushy" enough to trigger reliably
- [ ] dimensions.md is a clean reference, not over-described
- [ ] subagent-guide.md is brief, universal sections clearly separated from dimension-specific
- [ ] References linked from SKILL.md using markdown link syntax `[name](references/file.md)`
- [ ] marketplace.json alphabetically sorted
- [ ] README.md alphabetically sorted

**Step 2: Create test prompts**

Write 2-3 realistic test prompts that simulate different retro scenarios:

| # | Scenario | What to verify |
|---|----------|---------------|
| 1 | After a coding session with corrections and workarounds | Observation quality — does it catch corrections, inefficiencies, undocumented practices? |
| 2 | After a session with heavy skill/subagent usage | Tool ecosystem analysis — does it notice skill quality, orchestration patterns? |
| 3 | After a short session with minimal issues | Graceful handling — does it avoid over-analyzing when there's little signal? |

Save test prompts to `docs/plans/vp-retro-test-prompts.md` for reference.

**Step 3: Smoke test (iterate)**

In a session with meaningful work history (not a fresh session), try:
```
/retro
```

Evaluate:
- Does the skill trigger correctly?
- Are observations relevant and non-obvious?
- Does the interactive flow feel natural (not rigid)?
- Do subagent deep-dives produce actionable options (description, differences, examples, recommendation)?
- Does action planning present context-aware execution options?

**Step 4: Iterate based on feedback**

Based on test results:
1. Adjust SKILL.md wording if the flow feels too rigid or too vague
2. Adjust dimensions.md if signals are being missed or over-detected
3. Adjust subagent-guide.md if deep-dive results lack actionable options
4. Repeat test until satisfied

**Step 5: Description optimization (optional)**

If triggering accuracy is a concern, use the skill-creator description optimization loop:
- Create 20 eval queries (10 should-trigger, 10 should-not-trigger)
- Run optimization to find the best description wording

**Step 6: Final commit**

---

## File Summary

| File | Purpose | Size Target |
|------|---------|-------------|
| `.claude-plugin/plugin.json` | Plugin metadata | ~15 lines |
| `skills/retro/SKILL.md` | Main skill — philosophy, phases, guidelines | ~150-200 lines |
| `skills/retro/references/dimensions.md` | 15 analysis dimensions checklist | ~50-70 lines |
| `skills/retro/references/subagent-guide.md` | Universal subagent behavior guide | ~80-100 lines |

Total: 4 files, ~350 lines of content.
