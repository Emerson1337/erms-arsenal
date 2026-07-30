---
name: test-plan
description: The required test plan format — numbered scenarios, each with a route path, a concrete click-through action chain, and its own before/after behavior table. Use whenever a test plan is requested, including the `## Test plan` section of a pull request description.
---

# Test Plan Format

Every test plan uses one format, whether it's asked for on its own or written into a pull request
description. 2 rules.

A test plan is a script someone else can follow without asking questions. Each scenario says where
to start, exactly what to do, and what changed.

## When to Apply

- The words "test plan" appear in a request
- Writing the `## Test plan` section of a pull request body
- Asked how to verify, QA, or manually check a change

## The Format

```markdown
## Test plan

### 1. Install a preset arsenal
path: /settings/presets
action: Click "Install" -> pick repo B (/settings/presets/repo) -> type "erms" in the search field -> Enter

| Before | After (expected) |
| --- | --- |
| 500 on submit | Preset list renders |

### 2. Re-run the same install
path: /settings/presets
action: Click "Install" again

| Before | After (expected) |
| --- | --- |
| Duplicate row added | Skipped silently |
```

Three parts per scenario, always in this order:

1. A numbered heading saying what the scenario proves
2. `path:` then `action:`, one line each
3. Its own Before / After (expected) table, directly underneath

## Rules Summary

### format (HIGH) — @rules/format.md

`path:` is the route as it appears in the address bar. `action:` is one line of imperative steps
joined by ` -> `, with real values in quotes. The table is per scenario, one row per assertion.

```markdown
### 3. Reject an oversized upload
path: /projects/:id/files
action: Click "Upload" -> choose a 12 MB PNG -> Click "Confirm"

| Before | After (expected) |
| --- | --- |
| Spinner never stops | Error reads "File must be under 5 MB" |
| File appears in the list | List unchanged |
```

### scenario-coverage (MEDIUM) — @rules/scenario-coverage.md

Cover the happy path, each changed branch, the regression being prevented, and any re-run or
migration path. The Before column is observed on the base branch, never guessed.

```markdown
| Before | After (expected) |
| --- | --- |
| unknown — not reproducible locally | Row saves and the toast reads "Saved" |
```
