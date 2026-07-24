---
title: The two approval gates
impact: HIGH
tags: [workflow, approval, safety]
---

# The two approval gates

This skill is approve-gated by design: the user sees every proposed change, reply, and commit before it happens.

## GATE 1 — before any local edit

Presented in Phase 3. A per-comment plan: the reviewer's point, your verdict (valid / invalid / out-of-scope / question), the concrete fix, and the draft reply.

- Approval is **per comment**, not all-or-nothing.
- Apply only what's approved.
- A denied "valid" comment becomes a reply explaining that it won't change.

**Never edit a file before GATE 1 passes.**

## GATE 2 — before commit or any GitHub write

Presented in Phase 5. One consolidated summary: the diff, the proposed commit message(s), and the exact reply text per thread plus which threads resolve.

- Single go/no-go, but any reply or message can still be edited here.
- Only after "go": commit, post replies, resolve threads.

**Never commit, reply, or resolve before GATE 2 passes.**

## What needs no gate

Read-only inspection is always fine and should be thorough:

- Fetching comments; reading code at the referenced lines.
- Running typecheck, lint, or a test to verify a reviewer's claim.
- Checking out the PR branch.

Verifying claims before Phase 3 is what makes GATE 1 accurate. Do it freely.

## Why gated

Reviewer suggestions are sometimes wrong, and posted replies and commits are outward-facing and hard to walk back. The user owns the final wording and the decision on each point. The gates keep the skill fast to run while leaving them the sole author of what teammates see.

## Rules

1. Two gates: before local edits, and before commit/reply/resolve. Both are hard stops.
2. GATE 1 is per-comment; GATE 2 is one go/no-go with edit rights.
3. Read-only verification is ungated — use it to make the plan accurate.
4. Nothing outward-facing happens on your own initiative.
