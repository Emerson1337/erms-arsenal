---
title: Resolve what's being transported
impact: HIGH
tags: [hotfix, git, commits, pull-requests]
---

# Resolve what's being transported

Everything downstream — the cherry-picks, the tags, the notes — is built from one list of commits. Get that list wrong and every environment gets the wrong patch.

**Name the exact commits and show them to the user before anything is created.** Not "the changes in the working tree" — the SHAs and their subjects.

## Which entry point

Detect it, don't ask:

| Signal | Entry point |
| --- | --- |
| Argument is a PR URL or `#<number>` | An open PR |
| Argument is one or more SHAs | Existing commits |
| No argument, working tree dirty | Local uncommitted work |
| No argument, local commits ahead of the remote | Local commits |
| No argument, tree clean and nothing ahead | Nothing to transport — ask what the fix is |

```bash
git status --porcelain
git log --oneline @{u}..HEAD 2>/dev/null
git rev-parse --abbrev-ref HEAD
```

## From an open PR

```bash
gh pr view <number> --repo <slug> --json number,title,body,headRefName,baseRefName,state,mergedAt,commits,url
```

- **The fix commits** are that PR's commits. Take them from the `commits` field, oldest first.
- **The PR's base is already a participating environment.** Don't create a second branch for it — that PR *is* that environment's PR. Fan out to the remaining branches only.
- **A merged PR is fine** — that's the common case, someone shipped to one environment and the rest need it. Use its commits and treat its base as already done.
- **A squash-merged PR collapses to one commit on the base.** Its listed commits no longer exist there. Use the squash commit instead:
  ```bash
  gh pr view <number> --repo <slug> --json mergeCommit -q '.mergeCommit.oid'
  ```
- Reuse the PR's title and body as the basis for every fan-out PR, so all environments describe the same fix the same way.

## From SHAs

```bash
git -C <path> show --no-patch --format='%H %s' <sha>
```

Verify each SHA exists and is reachable from some branch. Reject a SHA that only exists in a local detached state — it can't be pushed as part of a cherry-pick from another branch's base. Keep the order the user gave; if they gave them in reverse chronological order, re-sort oldest-first and say you did.

## From local uncommitted work

This is the "just commit it and open the PRs" path. Three things must happen before a fan-out exists, in this order.

### 1. Show the diff and confirm the scope

```bash
git status --porcelain
git diff --stat
git diff --stat --cached
```

**Read the diff, not just the file list.** Then state what you're about to commit and get confirmation.

**Refuse to widen the scope.** If the tree holds changes unrelated to the fix — a stray formatting pass, a debug `console.log`, an unrelated file, a lockfile churn — do not commit them into a hotfix. Say which files look unrelated and ask the user to stash or discard them:

```bash
git stash push -- <unrelated-path>
```

A hotfix is the change most likely to be merged without careful review, on every branch at once. It carries the fix and nothing else.

### 2. Establish the base branch

The hotfix has to be based on the environment it's fixing. If the current branch is one of the fan-out targets, that's the base. If it's a feature branch, ask which environment the bug is on — usually production — and branch from that:

```bash
git -C <path> fetch origin <base-branch> --quiet
git -C <path> switch --create <branchPrefix><slug>-<base-branch> origin/<base-branch>
```

> **Why the base matters:** the first branch's base decides what the fix's diff means. Committing a production fix on top of an unreleased `develop` mixes unshipped work into the patch, and every cherry-pick after it inherits that mistake.

If the working tree was based on a different branch, carry the changes over rather than re-branching under them — stash, switch, pop, and re-check the diff.

### 3. Commit

One commit unless the fix genuinely has separable parts. Message follows the repo's existing convention — read it, don't assume:

```bash
git -C <path> log --pretty=%s -20
```

Include the ticket key in the form the repo already uses when `tracker.prefix` is set. No AI attribution anywhere in the message — see the global git rules in `CLAUDE.md`.

Then push and treat these commits as the fix list.

## Derive the slug

The branch name suffix and the announcement both need a short handle. Derive it from the ticket key when there is one, otherwise from the fix's subject: lowercase, hyphenated, three or four words, no ticket punctuation.

```
[<KEY>-<n>] Fix login crash on expired session  ->  <key>-<n>-login-crash
Fix login crash on expired session              ->  login-crash-expired-session
```

## Before continuing

Show the user, and get confirmation:

1. The commits — SHA and subject, oldest first
2. The base branch they came from
3. The slug, and therefore what every hotfix branch will be called
4. Whether any of them touch `migrations.glob`

Then hand this list to `rules/fan-out.md`. It does not re-derive it.

## Rules

1. Name the exact commits before creating anything; never work from "the current changes".
2. A hotfix carries the fix and nothing else — refuse unrelated working-tree changes rather than sweeping them in.
3. An existing PR's base is already a participating environment; don't duplicate it.
4. For a squash-merged PR, transport the squash commit, not its collapsed originals.
5. Base the first branch on the environment being fixed, not on whatever branch happens to be checked out.
6. Read the repo's commit-message convention from its log instead of assuming one.
