---
name: prename
description: >-
  Generate a meaningful session name based on the overall session theme, not just
  the last action. Use when asked to "name this session", "rename session",
  "prename", "give this session a name", "what should I call this session",
  or when the user invokes /prename.
  Outputs a /rename command for the user to execute.
  Boundary: not for renaming files, variables, or git branches.
---

# Prename

Generate a session name that captures the **overall theme and purpose**, not just the last action.

## Process

Dispatch naming to a **haiku subagent** — this task is lightweight and doesn't need a heavy model.

1. Summarize the conversation's key themes in 2-3 sentences
2. Spawn a haiku subagent with the summary and the naming style below
3. The subagent returns the `/rename` command
4. Output the result directly — nothing else

## Naming Style

`<emoji> <topic>`

- **Emoji** — reflects session nature, freely chosen
- **Topic** — the essence of the session; can be a noun, a phrase, or include a verb when it clarifies (e.g., `fix CI: node version mismatch`)
- **Reference-driven sessions** — when the session revolves around a specific reference (PR, issue, ticket), use its title: `#42 Fix auth timeout`, `PROJ-123 User onboarding flow`
- **Language** — match the user's language or the natural fit for the context; mixing is fine
- **Keep it scannable** — aim for 1-5 words after the emoji

## Examples

```
🔌 vp-prename
🐛 fix CI: node version mismatch
⬆️ React 19 upgrade
⏪ revert abc123 auth regression
📚 MCP server: stdio vs SSE
🔧 #42 Fix auth timeout
🔀 auth middleware refactor
🎫 PROJ-123 User onboarding flow
🧪 session naming
🔌 vp-deps-shift improvements
💬 architecture decisions
```

## Anti-patterns

- Last action only: `fix README typo` when the session built an entire plugin
- Too generic: `coding session`, `work`
- Too specific: `add handleTimeout to auth/middleware.ts line 42`

## Output

Output ONLY the rename command, nothing else:

```
/rename <emoji> <topic>
```
