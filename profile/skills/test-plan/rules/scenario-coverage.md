---
title: Which Scenarios to Include
impact: MEDIUM
impactDescription: whether the plan actually covers the change
tags: testing, pull-requests, conventions
---

## Which Scenarios to Include

Cover the happy path, every changed branch, the regression being prevented, and any re-run or
migration path. Nothing else.

### Why

1. **A plan that only walks the happy path proves nothing about the fix** — the bug lived in a branch
2. **Unlisted branches don't get checked** — reviewers run what's written
3. **A guessed Before column is worse than none** — it sends the reader looking for a symptom that
   never existed, and they conclude the plan is wrong

### What to Cover

| Include                                  | Why                                             |
| ---------------------------------------- | ----------------------------------------------- |
| The happy path                           | Proves the feature works at all                 |
| Each branch the diff added or changed    | That's where the behavior actually changed      |
| The regression this change prevents      | Proves the reported bug is gone                 |
| Re-running the same action               | Idempotency, duplicates, double submits         |
| The migration or upgrade path            | Existing data and existing installs still work  |
| Permission or role differences, if touched | An admin-only path passing says nothing about a member |

### What to Leave Out

- Scenarios covering code the diff didn't touch
- Framework behavior (routing works, forms submit)
- Anything already asserted by an automated test in this change — reference the test instead:
  `Covered by e2e/tests/upload.spec.ts`

### The Before Column Must Be Observed

Determine it, don't infer it:

1. Read the code on the base branch and trace the actual outcome, or
2. Check out the base branch and run it, or
3. Use the bug report, if it describes an observed symptom

If it genuinely can't be determined, say so in the cell rather than inventing something:

```markdown
| Before | After (expected) |
| --- | --- |
| unknown — not reproducible locally | Row saves and the toast reads "Saved" |
```

For a brand-new feature there is no prior behavior, and the honest Before is the absence:

```markdown
| Before | After (expected) |
| --- | --- |
| No "Install" button on the page | "Install" button opens the repo picker |
```

### How Many

One scenario per behavior worth checking. Three focused scenarios beat one that chains eight steps —
when a long chain fails at step six, nobody knows which change caused it.

### Summary

| Rule                                                       |
| ---------------------------------------------------------- |
| Happy path, changed branches, the regression, re-run paths  |
| Skip untouched code, framework behavior, already-tested paths |
| Before is observed on the base branch, never guessed        |
| `unknown — <reason>` is allowed; a made-up symptom is not   |
| New features: Before is the absence of the thing            |
| One behavior per scenario, not one long chain               |
