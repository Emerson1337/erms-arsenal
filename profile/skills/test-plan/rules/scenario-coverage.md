---
title: How Much to Cover
impact: MEDIUM
impactDescription: whether the plan gets read and run, or skimmed and skipped
tags: testing, pull-requests, conventions
---

## How Much to Cover

**Ceiling: 3 scenarios, 2 table rows each.** Stay under it. A plan that needs more is documenting
the diff instead of verifying it.

### Why

1. **A long plan doesn't get run** — the reader skims it, tests the first case, and moves on. Three
   scenarios someone actually executes beat seven they scroll past
2. **Listing unchanged behavior buries the changed behavior** — "Unchanged" rows are noise the
   reader has to read before finding the assertion that matters
3. **The reviewer already has the diff** — the plan says how to see the change, not what the change
   was

### What Earns a Scenario

In priority order. Take the first two or three that apply, then stop:

| Include                                          | Why                                            |
| ------------------------------------------------ | ---------------------------------------------- |
| The behavior the ticket asked for                 | The whole point — if this passes, the fix works |
| The case that would silently regress              | Where a wrong fix does damage nobody notices   |
| One genuinely separate surface the diff touched   | A second entry point, a second screen          |

### What Never Earns One

- **A path listed only to prove it's unchanged.** If the diff can't plausibly break it, leave it out
- Framework behavior — routing, form submits, a button navigating
- Error and network-failure paths, unless the change is about error handling
- Permission or role variants, unless the change touched authorization
- Anything an automated test in this change already asserts — reference it instead:
  `Covered by e2e/tests/upload.spec.ts`
- A re-run, migration, or idempotency case, unless the change is about re-running or data shape

### Rows

One row per assertion that **decides pass or fail**. Not every visible difference.

Skip rows for colors, icons, exact wording of text the change didn't touch, and anything a reader
would never fail the plan over. If a scenario needs three rows, one of them is probably decoration.

### The Before Column Must Be Observed

Determine it, don't infer it: read the base-branch code and trace the outcome, run the base branch,
or use the bug report if it describes an observed symptom.

If it genuinely can't be determined, say so rather than inventing a symptom — a made-up Before sends
the reader hunting for something that never existed:

```markdown
| Before | After (expected) |
| --- | --- |
| unknown — not reproducible locally | Row saves and the toast reads "Saved" |
```

For a brand-new feature the honest Before is the absence:

```markdown
| Before | After (expected) |
| --- | --- |
| No "Install" button on the page | "Install" button opens the repo picker |
```

### When the Plan Can't Be Run Yet

Say it once, above the scenarios, in one line — not as a note on every affected scenario:

```markdown
Scenario 1 needs the backend PR deployed; until then the banner reads the old text.
```

### Summary

| Rule                                                                    |
| ----------------------------------------------------------------------- |
| Hard ceiling: 3 scenarios, 2 rows each                                  |
| Cover the asked-for behavior, then the silent regression, then stop      |
| Never add a scenario just to show something is unchanged                 |
| One row per pass/fail assertion — no cosmetic rows                       |
| Before is observed on the base branch; `unknown — <reason>` beats a guess |
| Blockers stated once, above the scenarios                               |
