<!-- Shared: deps-upgrade (source of truth) / deps-migrate (copy). Keep in sync. -->

# Context7 MCP Integration

## Overview

Context7 provides up-to-date documentation lookup via MCP tools. It's optional but significantly improves documentation quality for dependency upgrades and migrations.

## Availability Detection

Attempt to call `resolve-library-id` with a known library. If the tool is available, Context7 is installed.

```
1. Call resolve-library-id(libraryName: "<package>", query: "<migration/upgrade context>")
2. If succeeds → Context7 is available, proceed with query-docs
3. If fails (tool not found) → Context7 not installed
```

## When Context7 Is Available

### For deps-upgrade (version upgrade)

1. `resolve-library-id(libraryName: "<package>", query: "migration guide from v<old> to v<new>")`
2. `query-docs(libraryId: "<resolved-id>", query: "breaking changes v<old> to v<new> migration")`
3. Use results alongside changelog analysis (parallel, not replacement)

### For deps-migrate (library replacement)

1. Query **source** library: `resolve-library-id(libraryName: "<source>", query: "API reference for migration")`
2. Query **target** library: `resolve-library-id(libraryName: "<target>", query: "migration from <source> getting started")`
3. Use both results to build API mapping table

### Query Tips

- Be specific: "breaking changes React 18 to 19" is better than "React docs"
- Query for migration guides specifically — they contain the most relevant information
- For library replacement, query both source and target libraries
- Combine Context7 results with changelog and code analysis for completeness

## When Context7 Is Not Available

1. **Inform user**: "Context7 plugin provides better documentation lookup for dependency upgrades"
2. **Suggest installation**: `/plugin install context7@context7-marketplace`
3. **Ask**: "Want to proceed without Context7? I'll use changelog, releases API, and code analysis instead."
4. **Continue with fallbacks**:
   - `gh api repos/{owner}/{repo}/releases` for release notes
   - Parse `CHANGELOG.md` in the package repository
   - Search for `MIGRATION.md` or `UPGRADING.md`
   - Analyze source code diffs between versions
   - Web search for community migration guides

## Important Notes

- Context7 is a **parallel source**, not a fallback chain — always use changelog + releases too
- Context7 results may not cover every breaking change — code analysis is still needed
- Maximum 3 `query-docs` calls per question to avoid excessive API usage
- If Context7 returns incomplete results, supplement with other sources rather than retrying
