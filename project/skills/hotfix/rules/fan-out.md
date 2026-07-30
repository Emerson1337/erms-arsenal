---
title: Fan the fix out to every environment
impact: HIGH
tags: [hotfix, git, cherry-pick, pull-requests, conflicts]
---

# Fan the fix out to every environment

One branch per target, the fix cherry-picked onto it, one PR per target. Targets are every participating tier's `branch` plus `trunk.branch`.

> **Why a branch per environment instead of one branch with several PRs:** environment branches diverge. A single branch based on production, PR'd into a lower environment, proposes not just the fix but every production-only commit that environment is missing. A cherry-pick onto each base makes every PR's diff exactly the fix, and makes a conflict a per-environment problem instead of a mystery in a shared diff.

## Per target

For each target branch `<branch>` in each participating repo:

```bash
git -C <path> fetch origin <branch> --quiet
git -C <path> switch --create <branchPrefix><slug>-<branch> origin/<branch>
git -C <path> cherry-pick <sha>...            # oldest first, in order
git -C <path> push --set-upstream origin <branchPrefix><slug>-<branch>
```

Then open the PR:

```bash
gh pr create --repo <slug> \
  --base <branch> \
  --head <branchPrefix><slug>-<branch> \
  --title "<title>" --body-file <f>
```

Work through the targets **in order, lowest environment first, trunk last** — the same order the merges will happen in. A conflict is most likely on the branch furthest from the fix's base, and hitting it early tells you what the rest of the fan-out is up against.

## Skip a target that already has it

Two cases, both real:

- **The entry point was a PR** — its base is already handled by that PR.
- **The fix is already merged into a target** — check before creating anything:
  ```bash
  git -C <path> branch -r --contains <sha> | grep 'origin/<branch>$'
  ```
  For a squash or rebase merge the SHA won't match even though the change is present, so also check whether the patch is already applied:
  ```bash
  git -C <path> cherry origin/<branch> <branchPrefix><slug>-<base>
  ```
  A `-` prefix means the patch is already there. Report the skip; don't open an empty PR.

An empty cherry-pick (`nothing to commit`) is the same signal — that environment already has the fix. Drop it from the fan-out and say so.

## Conflicts

A conflict is expected on at least one environment when the branches have drifted. It is **not** something to resolve silently.

```bash
git -C <path> cherry-pick <sha> || git -C <path> diff --name-only --diff-filter=U
```

When it conflicts:

1. Capture the conflicting files.
2. Abort, leaving the repo clean: `git -C <path> cherry-pick --abort`, then `git -C <path> switch -` and delete the branch.
3. **Continue with the remaining targets.** One blocked environment must not stop the others — the fix still needs to reach everywhere it can.
4. Report the blocked environment with its conflicting files, and ask how to proceed. Offer the two honest options: the user resolves it themselves, or they tell you exactly how and you redo that one branch.

> **Why abort instead of resolve:** a hotfix is the change most likely to be merged fast, with light review, on every branch at once. A mis-resolved conflict ships a subtly different fix to one environment while everyone believes all environments match. An unpatched environment is visible; a wrongly-patched one is not.

Never `-X ours`/`-X theirs` a hotfix conflict, and never skip a conflicting commit with `--continue` to make the cherry-pick finish.

## Verify each PR carries only the fix

Before showing the PR URLs, confirm each PR's diff is the fix and nothing more:

```bash
git -C <path> diff --name-status origin/<branch>...<branchPrefix><slug>-<branch>
```

Compare that file list against the fix's own diff. They should match on every environment. A longer list means the branch picked up something else — most often the base was wrong, or a conflict resolution over-reached. Stop and report it rather than opening the PR.

Also confirm the commit count matches the fix list:

```bash
git -C <path> rev-list --count origin/<branch>..<branchPrefix><slug>-<branch>
```

## The PR body

Same body on every environment, so the fan-out is legible as one change. Include:

- **What broke** — the symptom, as it was observed
- **The fix** — what changed and why that addresses it
- **Environments** — the full list of branches getting this same fix, with each PR's number once they exist, so a reviewer on one PR knows about the others
- **A `## Test plan`** in the `test-plan` skill's format: numbered scenarios with `path:`, a `->` chained `action:`, and a per-scenario Before / After (expected) table. The Before column here is the bug — that's the one place a hotfix's before/after writes itself.
- The ticket key when `tracker.prefix` is set

No AI attribution anywhere in the title or body — see the global PR rules in `CLAUDE.md`.

## Trunk's PR

Trunk gets the same treatment with two differences: it takes `trunk.mergeMethod` (usually squash, unlike the env branches), and it gets no tag and no deploy verification because nothing deploys from it.

Call it out separately in the hand-off. **An open trunk PR is the loose end that silently undoes the whole hotfix** — the env branches are patched, and the next release brings the bug back.

## Rules

1. One branch per target, created off that target, with the fix cherry-picked oldest-first.
2. Work the targets lowest environment first, trunk last.
3. Skip a target that already contains the patch — check with `git cherry`, not just SHA containment.
4. Abort on conflict, keep going with the other targets, and ask. Never resolve a hotfix conflict silently, never `-X ours`/`-X theirs`.
5. Verify every PR's diff and commit count match the fix before showing it.
6. The same body on every PR, listing all participating environments and a real test plan.
7. Trunk is a target. Report its state separately at hand-off.
