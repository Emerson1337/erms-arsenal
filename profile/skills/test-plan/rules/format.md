---
title: Test Plan Format
impact: HIGH
impactDescription: whether someone else can run the plan without asking questions
tags: testing, pull-requests, documentation, conventions
---

## Test Plan Format

Every scenario has a numbered heading, a `path:`, an `action:`, and its own before/after table.

### Why

1. **A plan is run by someone who didn't write the code** — every implied step is a question back
2. **`path:` removes the "where do I start" round trip** — the reader opens the app and is there
3. **Before/After makes pass and fail decidable** — "works correctly" isn't checkable; "the toast
   reads Saved" is
4. **Per-scenario tables mean no cross-referencing** — the expectation sits with the steps that
   produce it

### The Shape

```markdown
### 1. <what this scenario proves>
path: /settings/presets
action: Click "Install" -> pick repo B (/settings/presets/repo) -> type "erms" in the search field -> Enter

| Before | After (expected) |
| --- | --- |
| 500 on submit | Preset list renders |
```

### The Heading

Numbered, and it states what the scenario proves — not the mechanics. "Reject an oversized upload",
not "Upload test 2".

### `path:`

The route the scenario starts on, exactly as it appears in the address bar. Route params keep their
`:name` form.

```
path: /projects/:id/files
```

Not a UI change? Use whatever the entry point actually is:

```
path: POST /api/v1/presets
path: $ npm run arsenal:sync
```

### `action:`

One line. Imperative steps joined by ` -> `. Every step is written down — if a modal has to be
dismissed first, that's a step.

**Real values, in quotes.** `type "erms"`, never `type a search term`. The reader shouldn't have to
invent input, because a different input can produce a different result.

**Name the destination path on navigation**, in parentheses:

```
action: Click "Install" -> pick repo B (/settings/presets/repo) -> type "erms" -> Enter
```

Quote what's on screen, so it can be found: `Click "Confirm"`, not `Click the confirm button`.

### The Table

Directly under `action:`, per scenario. Headers are exactly `Before` and `After (expected)`.

- **Before** — the behavior on the current base branch. Not a restatement of the bug title, not
  "broken".
- **After (expected)** — the observable result, phrased so a reader can tell pass from fail.

Both columns describe what a person sees or receives. `The handler returns early` is not an
observation — `The row stays in the list and no request is sent` is.

**One row per assertion.** A scenario checking three things has three rows:

```markdown
| Before | After (expected) |
| --- | --- |
| Spinner never stops | Error reads "File must be under 5 MB" |
| File appears in the list | List unchanged |
| 500 in the server log | 400 in the server log |
```

### Bad: Too Vague to Run

```markdown
### 1. Test the upload
path: the files page
action: try uploading a big file

| Before | After (expected) |
| --- | --- |
| Broken | Works |
```

Four problems: the path isn't a route, "a big file" isn't a value, "Broken" isn't a behavior, and
"Works" can't be checked.

### Good: Runnable

```markdown
### 1. Reject an oversized upload
path: /projects/:id/files
action: Click "Upload" -> choose a 12 MB PNG -> Click "Confirm"

| Before | After (expected) |
| --- | --- |
| Spinner never stops, file is stored anyway | Error reads "File must be under 5 MB", nothing stored |
```

### Summary

| Part      | Rule                                                                |
| --------- | ------------------------------------------------------------------- |
| Heading   | Numbered, states what the scenario proves                           |
| `path:`   | The route as shown in the address bar; `:param` form kept           |
| `action:` | One line, ` -> ` between steps, real values quoted, no implied steps |
| Table     | Per scenario, `Before` / `After (expected)`, one row per assertion   |
| Wording   | What a person observes — never what the code does internally         |
