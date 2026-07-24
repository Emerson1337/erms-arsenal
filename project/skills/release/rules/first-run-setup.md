---
title: First-run setup — probe first, ask only what's left
impact: HIGH
tags: [setup, config, interview]
---

# First-run setup

Runs when `.claude/release.config.json` is absent, or when invoked as `/release setup`. Produces two files:

1. `.claude/release.config.json` — machine config, committed.
2. The runbook at `runbook` (default `docs/RELEASE.md`) — human-readable, committed, and ground truth from then on.

**Probe before you ask.** Every question you ask that the repo could have answered is a question that wastes the user's time and invites a wrong answer. Run the probes, show what you found, and ask only about what's genuinely a decision.

## Probe

```bash
# Identity + default branch + current merge settings
gh repo view --json nameWithOwner,defaultBranchRef,url

# Candidate tier branches (anything that isn't a feature branch)
git ls-remote --heads origin | awk '{print $2}' | sed 's|refs/heads/||'

# Workflows and what triggers them
ls .github/workflows/
grep -l -E '^on:|push:' .github/workflows/*.y*ml
grep -A5 -E '^on:' .github/workflows/*.y*ml     # read the branch filters

# Existing version tags → tagPrefix, prerelease convention, whether releases exist
git tag --list | tail -20
gh release list --limit 10

# Ticket-key convention in commit subjects (read the output, don't guess the prefix)
git log --pretty=%s -200 | grep -oE '^\[?[A-Z][A-Z0-9]+-[0-9]+' | sort | uniq -c | sort -rn | head

# Migration-ish directories
git ls-files | grep -iE 'migrat|schema' | head -20

# Sibling repos that might belong to a lockstep group
ls -d ../*/ 2>/dev/null
```

For each sibling that looks related, check whether it has the same tier branches (`git -C <path> ls-remote --heads origin`) — that's the signal for a lockstep group, and it's worth confirming rather than assuming.

## Ask

Only what the probes left open. Use `AskUserQuestion` with the probe results as the option labels — "I found branches `x`, `y`, `z`; which of these are deploy tiers?" beats an open prompt.

1. **Tiers** — which branches are deploy tiers, in order, and each tier's promotion source. Offer the branch list you found.
2. **Versioning per tier** — `prerelease`, `promote`, or `final` (explain each in one line). If tags already exist, infer the convention from them and confirm rather than ask cold.
3. **Lockstep** — one shared version across several repos, or each repo independent? Only ask if you found candidate siblings.
4. **Deploy verification** — for each tier and repo, which workflow deploys it and what in its log proves success. Offer the workflow files you found; if the user doesn't know, read the workflow and propose the grep patterns yourself.
5. **Migrations** — does a deploy apply schema migrations, and what's the file glob + the log line that reports what was applied? Skip entirely if you found no migration directory.
6. **Tracker** — which system, the ticket-key prefix (offer what the commit log showed), and the ticket URL template.
7. **Chat** — where releases are announced, and whether the agent may post there or must hand the text over. **Default to hand-over (`post: false`).**
8. **Public release notes** — should the skill also produce customer-facing notes, and where do they live (`CHANGELOG.md`, a store listing, nowhere)?

Write nothing until you've shown the assembled config and the user has confirmed it.

## Then audit

Run `rules/repo-settings-audit.md` as the last setup step and record the outcome in the runbook — the expected merge strategy per branch is part of the release contract, and setup is the natural moment to establish it.

## The runbook

The config is for you; the runbook is for humans (and for the next agent, per the fidelity rule). Generate it from the confirmed config, with a section per tier, and make it *specific*: real branch names, real workflow names, the actual verification commands. Structure:

```markdown
# Releasing <project>

## Branching model
<trunk + each tier, with the promotion direction and the merge method each branch uses>

## Versioning
<the scheme, what bumps where, what a prerelease looks like>

## Cutting a release into <tier>
<numbered steps: PR, tag, merge, watch, verify — with the real commands>

## Verifying the deploy
<per repo: the workflow, the log lines that prove success>

## Migrations
<when they run, against what, how to read the applied summary — or "none">

## Rollback
<delete the release + tag; whatever redeploy or revert path this project actually has>

## Announcing
<where, in what shape, who sends it>

## Gotchas
<anything discovered during setup that would bite the next person>
```

Leave a line at the top saying the file is the ground truth for release mechanics and that `.claude/release.config.json` is the machine-readable half — so a future reader knows which to edit.

## Rules

1. Probe before asking; every answer the repo can give, take from the repo.
2. Never invent a branch, workflow, tag prefix, or channel — an empty config field is strictly better than a wrong one.
3. Show the assembled config and get confirmation before writing either file.
4. Run the merge-settings audit as part of setup, and record its outcome in the runbook.
5. Write both files, then re-read the config you wrote and continue the release with it — don't proceed from memory.
