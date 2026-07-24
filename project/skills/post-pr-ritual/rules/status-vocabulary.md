---
title: Send the exact configured status string
impact: HIGH
tags: [tracker, api, status]
---

# Send the exact configured status string

`reviewStatus` from the config is sent **verbatim** — same case, same spacing, same punctuation. Tracker APIs match status names against each board's own vocabulary, and most match case-sensitively.

## Why exactness matters

- Every board defines its own status names. Two boards in the same workspace can use different strings for the same idea.
- A mismatch returns "status is not valid" and the ticket stays put — a visible failure, which is fine.
- Guessing a "close enough" variant is worse than failing. It either errors differently on each retry, or — the real hazard — succeeds against a status the team doesn't actually use, quietly parking the ticket somewhere nobody looks.
- Boards get renamed. A status that worked last quarter can be gone today. The config is the record; when it's stale, the user updates it, not you.

## Pattern

```jsonc
// Good — exactly what the config says
{ "task_id": "<key>", "status": "<reviewStatus verbatim>" }

// Bad — invented variants
{ "task_id": "<key>", "status": "<Title Cased>" }
{ "task_id": "<key>", "status": "<hyphenated-form>" }
{ "task_id": "<key>", "status": "<a synonym you remember>" }
```

## When the call fails

1. **Don't retry with a variant.** Not a different case, not a hyphen, not a synonym.
2. Confirm the comment step still landed — the steps are independent, so it should have.
3. If the tracker tool can enumerate the board's statuses, fetch them and show the user the actual list.
4. Surface the failing string and ask which status is right, then **update the config** so the next run works.

## Rules

1. Send `reviewStatus` verbatim from the config.
2. On rejection: never invent a replacement — escalate with the failing string and the board's real options.
3. Fix the config once the user names the right status; don't just work around it for this run.
4. A failed status move doesn't need the other steps undone.
