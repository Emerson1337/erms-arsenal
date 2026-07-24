---
name: address-pr-comments
description: Address review comments on a pull request end-to-end — evaluate each suggestion for correctness, apply the ones that hold up, and reply to plus resolve every open thread with short, direct answers. Use when the user pastes a PR link (or number) and asks to "address the comments", "handle PR feedback", "respond to review comments", "resolve the comments on <PR>", or invokes /address-pr-comments. Nothing is written to code, committed, or posted to GitHub until the user approves a single summary of every proposed change, reply, and commit.
---

# Address PR Comments

Take a PR, work through its review feedback, and leave every open thread answered and resolved — **approve-gated**: the user signs off on a full summary before anything is applied, committed, or posted.

Works on any repository. Nothing here is project-specific; conventions come from the repo you're in.

## When to apply

The user pastes a PR link or number and wants its feedback handled — "address the comments on this PR", "handle the review feedback", "respond and resolve the open comments", or `/address-pr-comments <url>`.

If no PR is given, ask for the link or number before doing anything.

## The hard rule: nothing lands without approval

Two side-effecting phases, each behind its own gate:

1. **Local code changes** — only after the change plan is approved (Phase 3 gate).
2. **Commit + GitHub replies + thread resolution** — only after the final summary is approved (Phase 5 gate).

Never edit a file, commit, post a reply, or resolve a thread before its gate passes. Read-only inspection — fetching comments, reading code, running typecheck/lint/tests to check a claim — needs no gate. Do it freely.

## Workflow

### Phase 1 — Gather

Parse the PR URL into `owner` / `repo` / `number`:

```
https://github.com/<owner>/<repo>/pull/<number>
```

Pull **every** feedback surface — inline review threads, review summary bodies, and issue-level PR comments. Exact commands in `rules/fetching-comments.md`. Ignore threads already resolved and your own prior replies. Make sure you're on the PR's branch locally so you evaluate and edit against the real code.

### Phase 2 — Evaluate each comment

Read the referenced code and decide — **verify, don't assume**. A reviewer suggestion can be wrong, outdated, or based on a misread. Classify each:

- **Valid → will change** — the point is correct; describe the concrete fix.
- **Valid → out of scope** — correct but too large for this pass; note it, reply explaining, don't force a change.
- **Invalid / already handled** — the code already does this, or the suggestion misreads it; plan a short reply explaining why, no change.
- **Question, not a change request** — just answer it.

Where a claim is checkable — types, lint, a behaviour — actually check it (run the project's typecheck, lint, or the relevant test; read the code) rather than guessing. Cite what you found.

### Phase 3 — Present the change plan (GATE 1)

Before touching any file:

```
Comment 1 — <reviewer> on <path>:<line>
  Says:     <one-line paraphrase>
  Verdict:  Valid → change
  Plan:     <the fix, one line>
  Reply:    "<short draft reply>"
```

Group by verdict. Ask for approval **per comment** (`AskUserQuestion` for a few discrete decisions, prose otherwise). Apply only what's approved. If one is denied or edited, adjust its reply accordingly ("not changing because …").

### Phase 4 — Apply approved changes locally

Only the approved edits, following the repo's own conventions — read its `CLAUDE.md` / contributing guide and match the surrounding code. Afterwards run the project's typecheck and lint over the touched area (get the real script names from `package.json` or the equivalent; don't assume). Do **not** commit yet.

### Phase 5 — Final summary (GATE 2)

One consolidated summary:

- **Diff** — `git diff --stat` plus the actual hunks, or a tight per-file description.
- **Commit(s)** — proposed message(s) following the repo's convention, inferred from `git log --oneline -20`. Ask whether one commit or several.
- **Replies** — the final text for each thread, and which threads will be resolved.

Single go/no-go. Nothing executes until the user says go; they can still edit any reply or message here.

### Phase 6 — Execute

Only after GATE 2:

1. Stage and commit the approved changes. **Don't push unless asked.**
2. Post each approved reply on its thread.
3. Resolve each answered thread.

Commands in `rules/replying-and-resolving.md`.

### Phase 7 — Confirm

Report tightly: what changed, commit SHA(s), which threads were replied to and resolved, and anything deliberately left open with why. Mention pushing if a push is expected.

## Style for replies

Short and direct. One or two sentences. State the resolution, not the reasoning tour.

- Good: "Done — extracted to a shared helper and reused here."
- Good: "Already handled: the guard returns early when unauthenticated, so this path can't throw."
- Bad: a paragraph restating the reviewer's comment before answering.

No AI or assistant attribution anywhere — not in commits, not in replies.

## Rules

- `rules/fetching-comments.md` — pull every comment surface.
- `rules/replying-and-resolving.md` — reply and resolve via `gh` / GraphQL.
- `rules/approval-gates.md` — the two gates and what must never precede them.
