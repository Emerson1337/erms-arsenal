---
description: Commit continuously while working — after every unit of work
---

# Commit as you go

Commit your work continuously while you build. Do not leave a session's changes
piled up in the working tree for the user to deal with.

## When to commit

Commit as soon as any of these is true:

- **A unit of work is finished** — a bug fixed, a function or component written,
  a file migrated, a test made to pass. If you could describe what you just did
  in one sentence, that is a commit.
- **You are about to change direction** — moving to a different file, feature, or
  layer of the codebase. Commit the thing you are leaving before you start the
  next one.
- **You are about to reply to the user** having edited files this turn. Commit
  first, then reply. This is the backstop: never end a turn leaving work you did
  uncommitted.

Do **not** wait to be asked, and do not ask for permission — committing is part
of doing the work, not a separate decision to run past the user.

## What a good commit looks like

- **Stage only what belongs to this change.** Reach for explicit paths
  (`git add src/foo.ts src/foo.test.ts`) over `git add -A`, which sweeps up
  unrelated edits, stray build output, and files someone else's session is
  working on.
- **Write a real subject line** describing what changed and why. Follow whatever
  convention the repo's recent history shows (`git log --oneline -20`). Never
  use a placeholder like "commit", "wip", or "update".
- **One concern per commit.** Several unrelated fixes belong in several commits,
  not one.
- **Commit working code.** The tree should be coherent at each commit — it does
  not have to be finished, but it should not be mid-edit or mid-rename. If a
  pre-commit hook fails, fix what it flagged and commit again.

## What this does not authorize

- **Do not push**, open a PR, or merge unless the user asks. Committing is local
  and recoverable; publishing is neither.
- **Do not commit secrets** — `.env` files, keys, tokens, credentials — even if
  they are already sitting in the working tree.
- **Do not commit onto a protected branch.** If the repo's instructions say work
  happens on a branch and `main` is never committed to, that still holds; commit
  onto the branch you are on and say something if that branch is `main`.
- This is about cadence, not about lowering the bar. Committing often does not
  mean verifying less, finishing less, or reporting less honestly.
