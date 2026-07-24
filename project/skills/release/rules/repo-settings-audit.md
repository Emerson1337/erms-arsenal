---
title: Audit the PR merge strategy per branch
impact: HIGH
tags: [github, branch-protection, rulesets, merge-strategy]
---

# Audit the PR merge strategy per branch

A release is only traceable if the branch history is. This audit checks that the repository enforces **one merge method per branch class** and reports every deviation. It runs during first-run setup, at the top of every release, and standalone via `/release audit`.

## The expected contract

| Branch | Merge method | Why |
| --- | --- | --- |
| `trunk.branch` (the integration branch) | **squash only** | Feature branches land as one clean commit per unit of work, so `git log` on trunk reads as a changelog and release notes derive cleanly from commit subjects. |
| every `tiers[].branch` (release branches) | **merge commit only** | A promotion PR must preserve the individual commits it carries. Squashing a promotion collapses N features into one opaque commit, breaks `LAST_FINAL..HEAD` note generation on the next tier, and makes the compare link useless. |
| rebase | **off everywhere** | Rebasing a promotion rewrites SHAs, so the commits on the tier branch no longer match the ones you tagged on the source. |

`trunk.mergeMethod` and each `tiers[].mergeMethod` in the config are the source of truth for what's expected — the table above is the default the config template ships with. If a project deliberately differs, the config says so and the audit checks against *that*.

## Probe

Repository-level settings — these gate which methods are *possible* at all:

```bash
gh api repos/<owner>/<repo> --jq '{
  allow_squash_merge, allow_merge_commit, allow_rebase_merge,
  allow_auto_merge, delete_branch_on_merge,
  squash_merge_commit_title, squash_merge_commit_message
}'
```

Per-branch enforcement lives in **rulesets** — that's the only GitHub surface that can pin a merge method to a specific branch:

```bash
gh api repos/<owner>/<repo>/rulesets --jq '.[] | {id, name, target, enforcement}'

# then, per ruleset id:
gh api repos/<owner>/<repo>/rulesets/<id> --jq '{
  name,
  enforcement,
  branches: .conditions.ref_name.include,
  merge_methods: (.rules[] | select(.type == "pull_request") | .parameters.allowed_merge_methods),
  reviews: (.rules[] | select(.type == "pull_request") | .parameters.required_approving_review_count)
}'
```

Because repo-level flags are repo-wide, the correct shape is: **enable both squash and merge commit at the repo level, then let a ruleset narrow each branch to one of them.** A repo with `allow_merge_commit: false` cannot have a compliant release branch no matter what its rulesets say — report that as the root cause rather than as three separate findings.

## Report

One table, expected vs. actual, then a verdict line:

```
Branch          Expected        Actual                     Status
<trunk>         squash only     squash, merge, rebase      ✗ no ruleset pins the method
<tier branch>   merge only      squash only                ✗ squash would flatten promotions
rebase          off             enabled repo-wide          ✗
```

State the consequence, not just the mismatch — "squash on a release branch collapses every promoted commit into one, so the next tier's notes and compare link break" is actionable; "allowed_merge_methods mismatch" is not.

## Propose fixes — never apply them unsilenced

Print the exact commands and **wait for the user to say go**. This changes repository-wide settings that affect every contributor; it is not yours to decide.

```bash
# Repo level: allow both, kill rebase, auto-delete merged branches
gh api --method PATCH repos/<owner>/<repo> \
  -F allow_squash_merge=true \
  -F allow_merge_commit=true \
  -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true
```

```bash
# Pin trunk to squash (new ruleset)
gh api --method POST repos/<owner>/<repo>/rulesets --input - <<'JSON'
{
  "name": "trunk-squash-only",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["refs/heads/<trunk>"], "exclude": [] } },
  "rules": [
    { "type": "pull_request",
      "parameters": {
        "allowed_merge_methods": ["squash"],
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false
      } }
  ]
}
JSON
```

```bash
# Pin the release branches to merge commits (one ruleset can cover them all)
gh api --method POST repos/<owner>/<repo>/rulesets --input - <<'JSON'
{
  "name": "release-branches-merge-commit",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["refs/heads/<tier-a>", "refs/heads/<tier-b>"], "exclude": [] } },
  "rules": [
    { "type": "pull_request",
      "parameters": {
        "allowed_merge_methods": ["merge"],
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false
      } }
  ]
}
JSON
```

When a ruleset already exists for that branch, **update it instead of adding a second one** — overlapping rulesets both apply and the intersection is confusing to debug. Fetch it, change only `allowed_merge_methods`, and PUT the whole body back:

```bash
gh api repos/<owner>/<repo>/rulesets/<id> > /tmp/ruleset.json
# edit allowed_merge_methods, keep every other parameter exactly as-is
gh api --method PUT repos/<owner>/<repo>/rulesets/<id> --input /tmp/ruleset.json
```

Carry the existing review requirements through unchanged. Never lower `required_approving_review_count`, never flip a protection off as a side effect of fixing a merge method.

## Degrade honestly

- **403 / no admin rights** → you can still read repo-level flags but not always rulesets. Report what you could check, say plainly that per-branch enforcement is unverified, and continue the release. This is a warning, never a blocker.
- **Classic branch protection only** (`gh api repos/<owner>/<repo>/branches/<branch>/protection`) → classic protection has no merge-method control at all. Say so, verify the repo-level flags, and record the per-branch expectation in the runbook as a documented convention. Don't pretend it's enforced.
- **Rulesets at the org level** can also apply and may not be visible from the repo endpoint. If repo-level rulesets look empty but the merge UI behaves as though restricted, say that an org ruleset may be in play rather than reporting "unenforced".

## Rules

1. Check against the config's `mergeMethod` values, not against a remembered convention.
2. Repo-level flags gate what's possible; rulesets pin per branch. Diagnose in that order.
3. Report consequences, not field names.
4. Never apply a settings change without explicit approval, and never widen or weaken an unrelated protection while fixing a merge method.
5. A finding never blocks the release — surface it and continue.
