# Verification Recipes

Specific commands, subagent prompts, and API endpoints for Phase 3 verification execution.

## Auto-Verification Recipes

Deterministic file/field checks. Each produces a definitive PASS/FAIL.

### Common Recipes

| Checklist Item | Command | PASS Condition |
|----------------|---------|----------------|
| Plugin name has `vp-` prefix | `jq -r '.name' plugin.json \| grep -q '^vp-'` | Exit code 0 |
| plugin.json has all required fields | `jq 'has("name","version","description","author","license")' plugin.json` | Returns `true` |
| SKILL.md has valid frontmatter | `awk '/^---$/{c++} c==2{exit}' SKILL.md && head -20 SKILL.md \| grep -q 'name:'` | Opening + closing `---` exist, `name:` field present |
| Plugins sorted alphabetically | `jq -r '.plugins[].name' .claude-plugin/marketplace.json \| sort -C` | Exit code 0 |
| Plugin registered in marketplace.json | `jq -r '.plugins[].name' .claude-plugin/marketplace.json \| grep -q '^vp-<name>$'` | Exit code 0 |
| Version updated | `git diff origin/main -- plugin.json \| grep -q '"version"'` | Exit code 0 (MEDIUM confidence — checks field presence in diff, not actual value change) |
| File exists | `test -f <path>` | Exit code 0 |
| JSON is valid | `jq empty <file>` | Exit code 0 |
| YAML frontmatter has required fields | `head -20 SKILL.md \| grep -q 'name:' && head -20 SKILL.md \| grep -q 'description:'` | Exit code 0 |
| No sensitive data in fields | `jq -r '.. \| strings' <file> \| grep -iqE '(password\|secret\|token\|api.?key)'; test $? -eq 1` | grep finds nothing |

### Custom Recipe Construction

For items not in the table above, construct a recipe:

1. Identify what the item is checking (file, field, format, ordering)
2. Choose the appropriate tool: `jq` for JSON, `grep` for text, `test` for file existence
3. Write a command that exits 0 on PASS, non-zero on FAIL
4. Verify the command works on a known-good and known-bad case

## CI Verification

### Fetch CI Status

```bash
gh pr checks <N> --json name,state,conclusion
```

### Parse Results

```bash
# All checks passed?
gh pr checks <N> --json conclusion --jq 'all(.[]; .conclusion == "SUCCESS")'

# Which checks failed?
gh pr checks <N> --json name,conclusion --jq '.[] | select(.conclusion != "SUCCESS") | "\(.name): \(.conclusion)"'

# Any pending?
gh pr checks <N> --json state --jq 'any(.[]; .state == "PENDING" or .state == "QUEUED")'
```

### Status Interpretation

| State | Conclusion | Result |
|-------|-----------|--------|
| COMPLETED | SUCCESS | PASS |
| COMPLETED | FAILURE | FAIL |
| COMPLETED | CANCELLED | FAIL (report as cancelled) |
| PENDING | — | PENDING |
| QUEUED | — | PENDING |

### When No CI is Configured

Detect available local commands:

```bash
# Check package.json scripts
jq -r '.scripts | keys[]' package.json 2>/dev/null

# Common test commands
npm test / pnpm test / yarn test / bun test
cargo test / go test ./... / pytest / bundle exec rspec
```

Offer local execution with user confirmation only.

## Shell Verification

Single-command checks. Each runs one command and checks exit code.

### Common Recipes

| Checklist Item | Command | Notes |
|----------------|---------|-------|
| No console.log | `! grep -rn 'console\.log' src/` | Invert: PASS when grep finds nothing |
| No TODO/FIXME | `! grep -rn 'TODO\|FIXME' src/` | Adjust path as needed |
| No debugger | `! grep -rn 'debugger' src/ --include='*.ts' --include='*.js'` | Language-specific |
| No unused imports | Prefer CI/lint check (e.g., ESLint `no-unused-vars`) | Reclassify as CI if linter is configured; grep is unreliable for this |
| No trailing whitespace | `! grep -rn ' $' src/` | May have false positives |
| No hardcoded URLs | `! grep -rn 'http://\|https://' src/ --include='*.ts'` | Heuristic — MEDIUM confidence |

### Recipe Guidelines

- Use `!` prefix to invert grep (PASS when pattern NOT found)
- **Detect source directories** from `tsconfig.json`, `package.json`, or directory structure — do not hardcode `src/`
- **Verify target directory exists** before running grep — a missing directory silently returns PASS (false positive)
- Always scope to relevant directories (avoid node_modules, dist, etc.)
- Add `--include` for language-specific checks
- Mark heuristic checks as MEDIUM confidence

## Scan Verification (Subagents)

For items requiring semantic understanding. Each scan runs as a Task subagent.

### Constraints

- **Max 5 subagents** per checklist execution
- **Must confirm** with user before launching
- Use `subagent_type=Explore` for read-only scans

### Subagent Prompt Templates

#### Secret Detection

```text
Scan the codebase for potential secrets, credentials, API keys, tokens, or passwords.
Check:
- Hardcoded strings that look like keys/tokens (high entropy, common prefixes like sk-, pk-, ghp_)
- Environment variable references that are hardcoded instead of using process.env
- Config files with actual credentials instead of placeholders

Report: List each finding with file:line and the suspicious pattern.
Result: PASS if no secrets found, FAIL if any suspicious patterns detected.
```

#### Documentation Completeness

```text
Check if documentation has been updated to reflect recent code changes.
Compare:
- README.md content against current feature set
- API documentation against exported functions/types
- Inline doc comments against function signatures

Report: List any documentation gaps found.
Result: PASS if docs are up-to-date, FAIL if significant gaps exist.
```

#### Changelog Entry

```text
Check if a changelog or release notes entry exists for the current changes.
Look for:
- CHANGELOG.md with an entry matching the current version or "Unreleased" section
- Changeset files (.changeset/*.md)
- Release notes in PR description

Report: Whether an entry was found and if it adequately describes the changes.
Result: PASS if changelog entry exists, FAIL if missing.
```

#### Error Handling Review

```text
Review error handling in the changed files.
Check:
- Try/catch blocks have meaningful error handling (not empty catches)
- Async operations have error handling
- Error messages are informative
- Edge cases are handled (null, undefined, empty arrays)

Report: List any inadequate error handling with file:line.
Result: PASS if error handling is comprehensive, FAIL if gaps exist.
```

#### Backward Compatibility

```text
Check if the changes maintain backward compatibility.
Look for:
- Removed or renamed exports
- Changed function signatures (added required params, changed types)
- Modified API response shapes
- Removed configuration options

Report: List any breaking changes found.
Result: PASS if backward compatible, FAIL if breaking changes detected.
```

## API Data Sources

> **Pagination**: All GraphQL queries below use `first: 100`. When `pageInfo.hasNextPage` is `true`, paginate using `after: endCursor`. Emit a warning to the user if pagination is needed (results may be incomplete on the first page).

### PR Body

```bash
# REST
gh pr view <N> --json body,author,updatedAt

# GraphQL (for more control)
gh api graphql -f query='
{
  repository(owner: "<OWNER>", name: "<REPO>") {
    pullRequest(number: <N>) {
      body
      author { login }
      updatedAt
    }
  }
}'
```

### PR Comments (Non-Review)

```bash
gh api graphql -f query='
{
  repository(owner: "<OWNER>", name: "<REPO>") {
    pullRequest(number: <N>) {
      comments(first: 100) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          databaseId
          body
          author { login }
          updatedAt
        }
      }
    }
  }
}'
```

### PR Review Thread Comments

```bash
gh api graphql -f query='
{
  repository(owner: "<OWNER>", name: "<REPO>") {
    pullRequest(number: <N>) {
      reviewThreads(first: 100) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          comments(first: 10) {
            nodes {
              body
              author { login }
            }
          }
        }
      }
    }
  }
}'
```

### Issue Body + Comments

```bash
# Issue body
gh api repos/{o}/{r}/issues/{n} --jq '{body, author: .user.login, updated_at}'

# Issue comments
gh api graphql -f query='
{
  repository(owner: "<OWNER>", name: "<REPO>") {
    issue(number: <N>) {
      comments(first: 100) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          databaseId
          body
          author { login }
          updatedAt
        }
      }
    }
  }
}'
```

## Confidence Scoring

| Level | Criteria | Example |
|-------|----------|---------|
| **HIGH** | Exact command pass/fail, deterministic output | `jq 'has("name")' → true` |
| **MEDIUM** | Pattern-based, possible false positive/negative | `grep -rn 'TODO'` (could match in comments about TODO handling) |
| **LOW** | Heuristic, requires interpretation | "No unused imports" via grep (misses dynamic imports) |
