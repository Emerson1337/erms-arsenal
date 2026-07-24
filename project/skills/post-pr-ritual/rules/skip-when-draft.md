---
title: Draft PRs get step 1 only
impact: MEDIUM
tags: [workflow, github, draft]
---

# Draft PRs get step 1 only

A draft PR isn't a handoff signal. Don't move the ticket to review or comment "PR open for review" while it's still draft — that pulls teammates onto code that isn't ready.

## Why

- The review status means **"someone other than the author should look at this now."** A draft explicitly doesn't want that.
- The comment says "open for review". Posting it before the PR is ready makes the ticket's history lie about state.
- GitHub already distinguishes draft from ready; the tracker should agree with that signal, not contradict it.

## How to detect

- `gh pr create` was called with `--draft`, or
- `gh pr view <n> --json isDraft` returns `true`, or
- the user said "open as draft", "WIP", or "don't request review yet".

Check this **before** running steps 2 and 3, not after.

## What to do instead

1. Still assign on GitHub (step 1) — that's ownership, not a review request.
2. **Skip** the ticket comment and the status move.
3. Say so: `PR #<n> opened as draft — skipping the ticket comment and review move until it's marked ready.`

When the PR is later marked ready (or the user says "mark it ready"), run steps 2 and 3 then.

## Rules

1. Check the draft flag before steps 2 and 3.
2. Assign regardless — draft doesn't mean unowned.
3. Confirm the deferral, so the user knows the ritual is paused rather than forgotten.
