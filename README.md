# erms-arsenal

A portable set of Claude Code presets: skills, global config, and working conventions. Clone it on a new machine or account, run one skill, and the whole working routine comes back.

**Everything here is generic.** No project names, no repository paths, no channel or ticket IDs, no handles. Config templates ship with empty values and are filled in by an interview on first run, and the filled config is written outside this repo.

## Install

```bash
git clone https://github.com/Emerson1337/erms-arsenal.git
cd erms-arsenal
claude
```

Then, in that session:

```
/arsenal-setup
```

The setup skill is in this repo's own `.claude/skills/`, so it's available the moment you start Claude Code in the clone — nothing to install first. It will:

1. Report what's already on this machine (nothing gets clobbered silently).
2. Ask which parts you want.
3. Copy the profile skills and merge the global config into `~/.claude`, backing up anything it touches.
4. Optionally import the project skills into a repository you name.
5. Interview you for a first project entry in the local registry.

Useful variants:

| Command | What it does |
| --- | --- |
| `/arsenal-setup --check` | Dry run — reports every action, writes nothing |
| `/arsenal-setup profile` | Profile skills + global config only |
| `/arsenal-setup project` | Import project skills into a repo |
| `/arsenal-setup registry` | Add a project to the local registry |

Re-running is safe: identical skills are skipped, differing ones ask first.

### Manual install

If you'd rather not run the skill:

```bash
cp -R profile/skills/*   ~/.claude/skills/
cp    profile/statusline-command.sh ~/.claude/
mkdir -p ~/.claude/arsenal
cp    profile/templates/projects.example.json ~/.claude/arsenal/projects.json

# merge these by hand — don't overwrite what's already there
cat profile/CLAUDE.md      # into ~/.claude/CLAUDE.md
cat profile/settings.json  # into ~/.claude/settings.json
                           # replace __CONFIG_DIR__ with the real path to ~/.claude

# per repository
cp -R project/skills/* <repo>/.claude/skills/
```

## What's inside

### `profile/` → `~/.claude/`

Invoked from any directory, works on any repository.

| Skill | What it does |
| --- | --- |
| `address-pr-comments` | Works through a PR's review feedback end-to-end — evaluates each suggestion, applies the ones that hold up, replies and resolves. Two approval gates: nothing is edited, committed, or posted without a go. |
| `daily-checkout` | End-of-day summary. Discovers the day's PRs, reviews, and direct commits across a project's repos, composes the update plus a tickets-worked-on list, sends both, and snapshots the day for later recall. |
| `clean-code-standards` | The standards under everything else: never `any`, never `as` assertions, never suppress a linter, never chain ternaries, comments as a last resort, object calisthenics at medium effort. |
| `test-plan` | One test plan format — numbered scenarios, each with a route `path:`, a chained `action:`, and its own before/after table. Used standalone and for the `## Test plan` section of a PR. |
| `frontend-*-best-practices` (9) | React, React Router, React Native/Expo, Tailwind, i18n, async, JS performance, accessibility, testing. |
| `owasp-security-check` | Security audit guidelines for web apps and REST APIs, OWASP Top 10 based. |
| `skill-writing-best-practices` | How to write skills like these. |

Plus `CLAUDE.md` (global working preferences — response style, code standards, test plans, and the git/PR rules), `settings.json` (permission model, statusline, env), and `statusline-command.sh`.

### `project/` → `<repo>/.claude/`

Act on one repository; their config is committed beside them so every contributor's agent reads the same thing.

| Skill | What it does |
| --- | --- |
| `release` | Cut a versioned release through the repo's deploy tiers — audit the merge settings, compute the version, open promotion PRs, tag before the deploy, stop for a human to merge, verify the deploy, roll the tag back on red, then write technical **and** public human-readable release notes. |
| `hotfix` | Transport one urgent fix to **every** environment branch plus trunk — resolved from an open PR, from local work, or from SHAs; cherry-picked per environment; one PR each; tagged per tier; deploys verified as they land; announced. Shares `release.config.json`. |
| `post-pr-ritual` | The standing handoff after a PR opens: assign it, comment the URL on the ticket, move the ticket to review. Draft PRs get the assign only. |

`release` and `post-pr-ritual` interview you on first use and write their config into the repo. `hotfix` has no config of its own — it reads `release.config.json`, so run `/release setup` first.

## The release skill

It's the centrepiece, so it's worth knowing what it does before you run it.

**First run in a repo** probes before it asks — the remote, the branch list, the workflow files and their triggers, existing tags, the ticket-key convention in the commit log, sibling repos that might form a lockstep group. Then it asks only what's left, and writes two files: `.claude/release.config.json` (machine-readable) and a runbook (`docs/RELEASE.md` by default) that becomes ground truth from then on.

**Merge-strategy audit.** It verifies that the repo enforces one merge method per branch class — squash on the integration branch, merge commits on release branches, rebase off — because a squashed promotion collapses N features into one opaque commit and breaks the next tier's release notes. Repo-level flags gate what's possible; a ruleset pins each branch. Findings are reported with their consequence, fixes are printed as exact commands and applied only with your approval, and a missing permission or classic-only branch protection is reported honestly rather than glossed over. Run it alone with `/release audit`.

**Tag before deploy, roll back on red.** The tag is created after the PRs are open but before the merge, because build pipelines commonly bake the latest release tag into the artifact. Then it stops — you merge. If any deploy comes back red, the release and tag are deleted in every participating repo, so no tag ever survives a red build.

**Two sets of notes.** The GitHub Release body is technical and complete. The public notes are plain-language New/Improved/Fixed, with every internal identifier stripped — shareable as-is as app-store text, a changelog entry, or a customer email. Regenerate them alone with `/release notes`.

## The hotfix skill

`/hotfix` is the same machinery pointed sideways. A release promotes one branch into the next tier; a hotfix puts **one fix on every environment branch at once**.

Call it with an open PR (`/hotfix 412`), with commit SHAs, or with nothing at all — then it commits the working tree onto a hotfix branch, refusing to sweep in unrelated changes. It cherry-picks the fix onto a branch created off *each* environment branch, so every PR's diff is exactly the fix even when the branches have drifted, and a conflict on one environment doesn't block the others. Conflicts are never resolved silently: it aborts that environment, names the conflicting files, and asks — a wrongly-patched environment is invisible in a way an unpatched one isn't.

**Trunk is a target too.** A fix that lands on the environment branches but not on trunk is a fix the next release deletes, so trunk gets its own PR and its own line in the hand-off.

Tags follow each tier's versioning scheme off one shared patch bump, created before the merges for the same reason `/release` does it, and rolled back across every environment if any deploy comes back red. The announcement reports each environment's real state — including the ones still in flight.

## Config lives outside this repo

| File | Scope | Committed? |
| --- | --- | --- |
| `~/.claude/arsenal/projects.json` | your projects: repos, org, tracker, chat destination | **never** |
| `~/.claude/arsenal/snapshots/<project>/` | rolling daily-checkout snapshots | **never** |
| `~/.claude/arsenal/backups/<timestamp>/` | whatever setup replaced | **never** |
| `<repo>/.claude/release.config.json` | that repo's tiers, deploy verification, tracker | yes, in that repo |
| `<repo>/.claude/pr-ritual.config.json` | that repo's assignee, review status, tracker | yes, in that repo |
| `<repo>/docs/RELEASE.md` | generated human runbook | yes, in that repo |

## Integrations

The workflow skills call operations — `send-message`, `comment-on-ticket`, `move-status`, `ticket-url` — and adapters map them onto a provider chosen in config. Trackers: ClickUp, Jira, Linear, GitHub issues, or none. Chat: Slack, Discord, or none.

**A missing integration degrades to hand-over, never to silence** — the skill composes the message and gives it to you. `none` is a fully supported setting, and chat posting is off by default.

ClickUp and Slack are the paths ported from working use. Jira, Linear, and Discord are written to the same contract but untested — verify them on something disposable first.

MCP connectors are **not** in this repo: they're provisioned per account in the client, with no local file to copy. Connect the ones you need (chat, tracker, GitHub) before expecting those skills to post anything.

## Staying generic

```bash
bash scripts/check-generic.sh
```

Greps for pattern classes — absolute home paths, chat object IDs, workspace hosts, ticket keys, long numeric IDs, emails, foreign GitHub references, and non-empty values in config templates — so the script itself holds no secrets. Run it before every commit. It exits non-zero on any hit and explains the two tiers of coverage in its header comment.

## Requirements

`gh` (authenticated), `git`, `jq` for the statusline, and `python3` for JSON validation during setup.
