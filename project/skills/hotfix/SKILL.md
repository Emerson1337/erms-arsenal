---
name: hotfix
description: Transport an urgent fix to every environment branch in this repository. Resolves the fix from an open PR, from local uncommitted work (committing and branching it), or from commit SHAs; cherry-picks it onto a branch per environment; opens one PR per environment plus trunk; tags each tier per its versioning scheme; stops for a human to merge; verifies each deploy as it lands and rolls every tag back if any is red; then announces it. Use when the user says "hotfix", "/hotfix", "hot fix this", "patch production", "ship this fix to all environments", "transport this fix to every branch", "cherry-pick this to all envs", or opens a fix PR and wants it carried to the other environments. Shares `.claude/release.config.json` with the `release` skill.
argument-hint: <pr-url|#number> | <sha>... | setup
allowed-tools: Bash, Read, Write
---

# Ship a hotfix to every environment

Same contract as `release`: you own **the fix's transport, version computation, the tags, and the notes** — a human owns merging and (unless configured otherwise) announcing. CI owns building and deploying.

The difference from a release is the shape of the fan-out. A release promotes one branch into the next tier. **A hotfix lands the same fix on every environment branch at once**, so no environment is left carrying the bug.

Everything project-specific comes from `.claude/release.config.json` — the same file the `release` skill uses. **Nothing here is hardcoded to a project.** If that config is absent, run `/release setup` first; there is no separate hotfix config.

## The flow in one breath

**Resolve the fix commits → compute the version → cherry-pick onto a branch per environment → open every PR at once → tag each tier → STOP for the human to merge in release order → verify each deploy as it lands → if any deploy is red, delete every tag.** You never merge PRs, you never resolve a cherry-pick conflict silently, and no tag survives a red build.

> **Why every environment, and why trunk too:** a fix merged only into production is a fix the next release deletes. The env branches keep the running apps correct; **`trunk.branch` keeps the fix alive** — it's where the next feature branches from. Trunk is not optional, and it's the step people forget.

## Modes

| Argument | What it does |
| --- | --- |
| *(none)* | Resolve the fix from the working tree: uncommitted changes get committed to a new hotfix branch; local commits ahead of the remote are used as-is. See `rules/fix-source.md`. |
| `<pr-url>` or `#<number>` | Use an already-open PR as the fix. Its base becomes one participating environment; the rest are fanned out from its commits. |
| `<sha>...` | Transport commits that already exist on some branch. |
| `setup` | Defer to `/release setup` — the config is shared. Say so rather than writing a second config. |

## Config

`.claude/release.config.json`. Read it exactly as `release` does — **an empty string or empty array means "not configured"**: infer it if you safely can, ask if you can't, skip the step if it doesn't apply, and never invent a branch, workflow, or channel.

What a hotfix reads:

- **`tiers[]`** — every tier's `branch` is a fan-out target. `env` and `label` name it in the announcement. `versioning` decides its tag. A tier's `source` is **ignored** — a hotfix does not promote.
- **`trunk.branch`** — also a fan-out target, and its `mergeMethod` applies to that PR.
- **`repos[]`, `deploy.<tier>`, `migrations`, `artifact`** — participation, deploy verification, and what to capture. Same as release.
- **`tracker`, `chat`, `releaseNotes`** — same as release.
- **`hotfix`** (optional block) — `branchPrefix` (default `hotfix/`), `tiers[]` to restrict the fan-out to a subset (empty = every tier), `mergeOrder` (`release` = lowest env upward, the default; `production-first`).

## Fidelity rule

If `runbook` is set, **read it before doing anything** and treat it as ground truth for this project's mechanics. If a command or name here disagrees with it, **the doc wins** — surface the discrepancy. Resolve concrete values from the runbook, the config, and the workflow files — never from memory, and never from another project you've seen.

## What a hotfix deliberately skips

- **The merge-settings audit.** It's a release-time contract check, not an incident-time one. Point at `/release audit` instead of running it here.
- **Promotion.** No tier's `source` is consulted and nothing is promoted between tiers.
- **The bump question.** A hotfix is a `patch` by definition. If the user insists on `minor`/`major`, that's a release — say so and hand them `/release`.

## Procedure

### 0. Resolve the request

1. `.claude/release.config.json` absent → tell the user to run `/release setup`, and stop. Do not write a config here.
2. Read the config, and the `runbook` if set.
3. Resolve the fix commits per `rules/fix-source.md`. **Do not continue until you can name the exact commits being transported** and have shown them to the user.
4. Determine participating repos (`test -d <path>`) and participating branches: every `tiers[].branch` (filtered by `hotfix.tiers` when set) plus `trunk.branch`. Confirm each exists on the remote:
   ```bash
   git -C <path> ls-remote --heads origin <branch>
   ```
   List the fan-out targets and **pause for confirmation** before creating anything. Abort only if a `required` repo is missing.
5. **Migration gate.** If the fix touches `migrations.glob`, stop and say so plainly: a migration cherry-picked into an environment whose database is behind can apply out of order. Get explicit confirmation per environment before continuing, and recommend splitting the schema change out of the hotfix.

### 1. Compute the version

One patch bump, shared by every environment — the fix is one change, so it gets one number.

```bash
git -C <path> fetch --tags --quiet
git -C <path> tag --list '<tagPrefix>*'
```

- `LAST_FINAL` = highest `<prefix>MAJOR.MINOR.PATCH` with no prerelease suffix, across **all participating repos**, semver-sorted (`sort -V`). Default `<prefix>0.0.0`.
- `TARGET` = `LAST_FINAL` with **patch** incremented.
- Then per tier, by its `versioning`:
  - `final` → `<prefix>TARGET`
  - `promote` → `<prefix>TARGET`. A hotfix creates the whole set at once, so a promote tier takes `TARGET` directly instead of inheriting from a prerelease that doesn't exist yet.
  - `prerelease` → highest existing `<prefix>TARGET-<prereleaseTag>.*` + 1, else `.1`
- **Dedupe.** Two tiers can resolve to the same tag (a `promote` tier and a `final` tier both take `TARGET`). Create each distinct tag **once**, targeting the most-production tier that claims it, and report which tiers share it.
- **Trunk gets no tag** — it isn't a tier and nothing deploys from it.

Announce the computed tags and **pause for confirmation** before touching anything.

### 2. Fan out — a branch and a PR per target

Per `rules/fan-out.md`, for every participating branch in every participating repo: create `<branchPrefix><slug>-<branch>` off that branch, cherry-pick the fix commits onto it, push it, and open a PR against that branch.

Open **every** PR before waiting for any merge, so no environment is forgotten. A cherry-pick conflict on one environment does not block the others — report it and carry on with the rest.

Each PR body states what broke, what the fix does, which other environments are getting the same fix, and a `## Test plan` section in the `test-plan` skill's format. No AI attribution anywhere — see the global PR rules in `CLAUDE.md`.

**You cannot merge these — the PR opener merges.** Show every PR URL with the environment it patches.

### 3. Create the tags — then STOP

Same discipline and the same reason as `release`: many pipelines resolve the latest Release tag at build time and bake it into the artifact, so the tag has to exist before the merge fires the build. Create each tier's Release targeting **its hotfix branch's HEAD** — the commit about to be merged:

```bash
SHA=$(git -C <path> rev-parse <branchPrefix><slug>-<branch>)
gh release create <tag> --target "$SHA" --title "<tag>" --notes-file <f> --repo <slug>
```

Add `--prerelease` for a tier whose `prerelease` is true. Notes come from `../release/rules/release-notes.md` over `LAST_FINAL..$SHA` — for a hotfix that range is short and the technical notes are mostly the fix itself; keep them honest rather than padding them. Under `lockstep`, a repo carrying no part of the fix still gets the shared tag with `- No changes since <LAST_FINAL>.`

If `deploy.<tier>.trigger` is `none` for a tier, tag that tier **after** its merge instead — there's no build to beat.

**This is the hotfix request — then STOP.** Show every PR URL and every tag, state the merge order, then **wait**. Do not merge anything, do not hunt for deploy runs, do not continue on your own. The next step begins when the user says a PR is merged.

### 4. After each merge — verify that environment's deploy

Merge order is `hotfix.mergeOrder`, default `release` — **lowest environment upward**, so the fix is proven on a lower environment before production takes it. State the order; the user merges.

As each PR lands, for that environment only:

```bash
git -C <path> fetch origin <branch> --quiet
RUN_ID=$(gh run list --repo <slug> --branch <branch> --limit 1 --json databaseId -q '.[0].databaseId')
gh run watch $RUN_ID --repo <slug> --exit-status
```

Never `gh workflow run` a push-triggered deploy. For `trigger: dispatch`, dispatch it and say so. For `trigger: none`, skip to the next environment.

Then verify per config: every regex in `deploy.<tier>.verify[]` must match the run log; `artifact.digestLogPattern` confirms a fresh artifact and captures the digest; `migrations.appliedLogPattern` is the **authoritative** applied list. Anything the config doesn't describe, verify by reading the workflow file — never assume a step exists.

**Report partial state honestly.** "2 of 3 environments merged and green; `develop` PR still open" is the correct report. Never imply the fan-out is complete while a PR is open, and don't let an unmerged lower environment stall a verified higher one — say which are done and which are outstanding.

### 5. Green, or roll every tag back

**All green** → the hotfix stands.

**Any red** → delete the Release *and* tag for **every** tier and repo in this hotfix, so no tag survives a red build:

```bash
gh release delete <tag> --repo <slug> --cleanup-tag --yes
```

Report exactly which environment failed and stop. The merged code stays on the branches; the version is simply untagged until a clean re-deploy. Never leave a tag on a red build, and never blindly re-run a workflow.

### 6. Hand off

Report: the version, and per environment the PR URL + merge state, deploy run URL + status, Release URL, and the verified digest. Then explicitly: **whether trunk has the fix yet** — an open trunk PR is the one loose end that silently undoes the whole hotfix.

Then produce:
1. The **public release notes**, per `../release/rules/release-notes.md`, when `releaseNotes.public` is true. A hotfix usually yields one `Fixed` bullet — one honest bullet beats three invented ones.
2. The **announcement**, per `rules/announcement.md`. Post it only when `chat.post` is `true`; otherwise hand over a single copy-pasteable block and name the destination.

## Guardrails

- **Never merge a PR.** Not the production one, not trunk's, not even when the user is waiting.
- **Never force-push** a shared branch, and never rewrite an existing env branch to carry the fix.
- **Never resolve a cherry-pick conflict silently.** Abort that environment, show the conflicting files, and ask. A mis-resolved hotfix is worse than an unpatched environment, because everyone believes it's fixed.
- **Never widen the scope.** Only the resolved fix commits get transported. If the working tree holds unrelated changes, `rules/fix-source.md` says how to refuse them.
- **Never invent a version, branch, workflow, or channel.** An empty config field means ask or skip.

## Rules

- `rules/fix-source.md` — resolving the fix commits from a PR, from local work, or from SHAs; committing and branching when there's nothing committed yet.
- `rules/fan-out.md` — the per-environment cherry-pick, conflict handling, and the check that each PR carries only the fix.
- `rules/announcement.md` — the hotfix announcement structure and its formatting invariants.
- `../release/rules/release-notes.md` — technical vs. public notes. Identical for a hotfix; not duplicated here.
- `../release/rules/integrations.md` — the tracker/chat adapter contract. Identical for a hotfix; not duplicated here.

> Those last two are paths into the sibling `release` skill, which the arsenal installs alongside this one. If `release` isn't present in this repo's `.claude/skills/`, say so once and degrade: notes from commit subjects, announcement handed over instead of posted.
