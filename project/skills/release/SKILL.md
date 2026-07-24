---
name: release
description: Cut a versioned release for this repository — or a lockstep group of repos — through its deployment tiers. Verifies the repo's PR merge settings, computes the shared version, opens the promotion PRs, creates the GitHub Release tag before the deploy fires, stops for a human to merge, verifies the deploy is green and rolls the tag back if it isn't, then writes both technical release notes and public human-readable release notes. Use when the user says "cut a release", "release to <tier>", "ship to <tier>", "promote <tier>", "tag a version", "/release", or otherwise wants to version and deploy a build through the branch tiers. On first run in a repo it interviews you and writes `.claude/release.config.json` plus a runbook.
argument-hint: <tier> [patch|minor|major] | setup | audit | notes
allowed-tools: Bash, Read, Write
---

# Cut a release

You own **version computation, the GitHub Release (tag + notes), and the release notes** — a human owns merging and (unless configured otherwise) announcing. CI owns building and deploying.

Everything project-specific comes from `.claude/release.config.json` in the repo you're releasing. **Nothing in this skill is hardcoded to a project.** If the config is missing, run first-run setup (`rules/first-run-setup.md`) before anything else.

## The flow in one breath

**Audit the merge settings → compute the version → open the promotion PRs → create the Release tag → STOP for the human to merge → the merge fires the deploy → verify it's green → if any deploy is red, delete the tag.** You never merge PRs, and no tag survives a red build.

> **Why the tag comes before the deploy:** many pipelines resolve the latest Release tag at build time and bake it into the artifact, so the running app can report its own version. That only works if the tag exists before the merge fires the build — otherwise the build bakes the *previous* version. Tagging first is therefore correct, and deleting the tag is the compensation when the deploy comes back red. If `deploy.*.trigger` is `none` (no automated deploy), tag *after* the merge instead — there is nothing to compensate for.

## Modes

| Argument | What it does |
| --- | --- |
| *(none or a tier name)* | Full release into that tier. If no tier is given and the config has exactly one, use it; otherwise ask. |
| `<tier> patch\|minor\|major` | Full release, bump pre-decided. Only meaningful for a tier whose `versioning` is `prerelease` or `final`. |
| `setup` | Re-run first-run setup (`rules/first-run-setup.md`) to rebuild the config and runbook. |
| `audit` | Only run the merge-settings audit (`rules/repo-settings-audit.md`) and report. Changes nothing. |
| `notes` | Only regenerate release notes for the latest tag (`rules/release-notes.md`). No tagging, no PRs. |

## Config

`.claude/release.config.json`, committed to the repo so every contributor's agent reads the same thing. `release.config.example.json` in this skill is the empty template. Rules for reading it:

- **An empty string or empty array means "not configured."** Infer it if you safely can, ask if you can't, and skip the step if it doesn't apply. Never invent a branch name, workflow file, or channel.
- **`tiers[]`** is ordered from earliest to latest. Each has `branch` (the deploy branch), `source` (the branch it promotes from — usually the previous tier's branch, or `trunk.branch` for the first tier), and `versioning`:
  - `prerelease` — tag `<prefix>X.Y.Z-<prereleaseTag>.N`, flagged as a GitHub pre-release. The `patch`/`minor`/`major` bump is decided at this tier. Re-cutting the same target bumps `N`.
  - `promote` — inherit the version from the newest prerelease and strip the suffix → final `<prefix>X.Y.Z`. No new bump.
  - `final` — apply the bump directly and tag a final version (for repos with a single tier and no rc stage).
- **`lockstep: true`** means every repo in `repos[]` gets the same version tag on every release, including repos with no changes. `false` means each repo versions independently — then only the repo you're in participates unless the user says otherwise.
- **`repos[]`** — `path` is relative to the repo you're running in (`.` is this repo). `required: true` repos abort the run when missing; the rest are warned about and skipped.
- **`runbook`** — if set, that file is ground truth. See Fidelity rule.

## Fidelity rule

If `runbook` is set, **read it before doing anything** and treat it as ground truth for this project's mechanics (accounts, registries, migration hosts, rollback, channel). If a command or name here disagrees with it, **the doc wins** — surface the discrepancy. Resolve concrete values from the runbook, the config, and the workflow files — never from memory, and never from another project you've seen.

## Procedure

### 0. Resolve the request

1. If `.claude/release.config.json` is absent → `rules/first-run-setup.md`, then continue.
2. Read the config, and the `runbook` if set.
3. Parse the argument → tier + bump. For a `prerelease`/`final` tier with no bump given, ask, restating the rule of thumb: **patch** = bug/UX fixes, **minor** = new features, **major** = breaking API or data-model changes. A `promote` tier takes no bump — it inherits.
4. Determine which repos participate: `test -d <path>` for each, and `git -C <path> ls-remote --heads origin <tier-branch>` for the tier branch. List participants; warn about every skip. Abort only if a `required` repo is missing.
5. Run the merge-settings audit (`rules/repo-settings-audit.md`). Report it inline. A finding is a **warning, not a blocker** — the user decides whether to fix it now or release anyway.

### 1. Compute the version

Gather tags from **every participating repo** so the version can never regress:

```bash
git -C <path> fetch --tags --quiet
git -C <path> tag --list '<tagPrefix>*'
```

- `LAST_FINAL` = highest `<prefix>MAJOR.MINOR.PATCH` with no prerelease suffix, across all participating repos, semver-sorted (`sort -V`). Default `<prefix>0.0.0` when there are none — the first lockstep release aligns every repo onto one number.
- **`prerelease` tier:** apply the bump to `LAST_FINAL` → `TARGET`. Find the highest existing `TARGET-<prereleaseTag>.*` across repos → next `N` = that + 1, else `1`. If an in-progress prerelease series exists for a *different* `TARGET` (the bump changed mid-cycle), warn and confirm before diverging.
- **`promote` tier:** find the highest prerelease across repos → strip the suffix → final version. If that final tag already exists, warn (already promoted).
- **`final` tier:** apply the bump to `LAST_FINAL`.

Announce the computed tag and **pause for confirmation** before touching anything.

### 2. Open the promotion PRs

For each participating repo, with `<src>` = the tier's `source` and `<tier-branch>` = its `branch`:

```bash
git -C <path> fetch origin <src> <tier-branch> --quiet
git -C <path> rev-list --count origin/<tier-branch>..origin/<src>   # commits to promote
```

1. **Skip repos 0 commits ahead** — nothing to promote, no PR, no deploy. Under `lockstep` they still get tagged in step 3.
2. For the rest, gather what's being promoted: `git -C <path> log --pretty="- %s" origin/<tier-branch>..origin/<src>`, plus — when `migrations.glob` is set — the added migration files:
   ```bash
   git -C <path> diff --name-status --diff-filter=A origin/<tier-branch>..origin/<src> -- '<migrations.glob>'
   ```
   > **This migration diff is a PREVIEW for the PR body only — it can undercount.** It shows files the source has that the tier branch lacks, but a migration runner keys on the *target database's* applied set, not the branch diff: a migration already file-present on the tier branch yet never applied to that tier's DB won't show up here but *will* apply on deploy. The authoritative list is the deploy log captured in step 4 — use that for the announcement.
3. Open the PR with a body describing what's new plus a `## Test plan` section:
   ```bash
   gh pr create --repo <slug> --base <tier-branch> --head <src> --title "<title>" --body-file <f>
   ```
   No AI attribution anywhere in the title or body — see the global PR rules in `CLAUDE.md`.

**You cannot merge these — the PR opener merges.** Show every PR URL with what it promotes. **Do not wait for merge yet** — the tag comes first.

> **Why alignment matters:** the tier branch has to be aligned with its source before tagging. An unaligned tier branch can be missing not just new migrations but the *migration wiring itself* if that lives on the source branch — then the deploy runs no migrations and the artifact boots against an un-migrated database. Merging the promotion PR is what brings the new work onto the branch.

### 3. Create the Release tag — then STOP

Create the GitHub Release in every participating repo (including no-change repos when `lockstep`), at the shared tag, targeting each repo's **promotion-source HEAD** — the commit being promoted, since the tier-branch merge commit doesn't exist yet:

```bash
SHA=$(git -C <path> rev-parse origin/<src>)
```

- **Notes** — generate per `rules/release-notes.md` over the range `LAST_FINAL..$SHA`, using the captured `$SHA`, **not** live `origin/<src>`: pinning to the tag target keeps the notes matching the tagged commit even if the source branch advances afterwards. A no-change repo gets `- No changes since <LAST_FINAL>.` (for a repo's first-ever tag, frame it as the inaugural baseline instead of dumping the whole history).
- Pre-release tier: `gh release create <tag> --prerelease --target "$SHA" --title "<tag>" --notes-file <f> --repo <slug>`
- Final tier: `gh release create <tag> --target "$SHA" --title "<tag>" --notes-file <f> --repo <slug>`

**This is the release request — then STOP.** Show every PR URL and the tag you created, then **wait**. Do not merge anything, do not hunt for deploy runs, do not continue to step 4 on your own. The next step begins only when the user says the PRs are merged.

### 4. After merge — find, watch, and verify the deploys

For every repo that got a merge, when `deploy.<tier>.trigger` is `push` the merge already fired the workflow:

```bash
git -C <path> fetch origin <tier-branch> --quiet
RUN_ID=$(gh run list --repo <slug> --branch <tier-branch> --limit 1 --json databaseId -q '.[0].databaseId')
gh run watch $RUN_ID --repo <slug> --exit-status
```

Never `gh workflow run` a push-triggered deploy — it fires on the branch push. For `trigger: dispatch`, dispatch it explicitly and say so. For `trigger: none`, skip to step 5.

Then verify each repo per its config:

- Every regex in `deploy.<tier>.verify[]` must match the run log:
  ```bash
  gh run view $RUN_ID --repo <slug> --log | grep -E '<pattern>'
  ```
- `artifact.digestLogPattern`, when set → confirm a **fresh** artifact was published, and capture the digest/version for the announcement.
- `migrations.appliedLogPattern`, when set → confirm the migration step ran and capture its applied summary. **This is the authoritative migration list** — the step-2 branch diff can undercount it. If the run has no migration step at all but the config says it should, the branch wasn't aligned: stop and flag it.

Anything the config doesn't describe, verify by reading the workflow file — never assume a step exists.

### 5. Green, or roll the tags back

**All green** → the release stands; the step-3 tags are the release.

**Any red** → delete the Release *and* tag in **every** participating repo, so no tag survives a red build:

```bash
gh release delete <tag> --repo <slug> --cleanup-tag --yes
```

Report exactly which repo failed and stop. The merged code stays on the branch; the version is simply untagged until a clean re-deploy. Never leave a tag on a red build, and never blindly re-run a workflow.

### 6. Hand off

Report: the version, and per repo the merged PR URL, deploy run URL + status, Release URL (or "no changes — lockstep-tagged"), and the verified digest/version.

Then produce, per `rules/release-notes.md`:
1. The **public release notes** — plain-language, shareable as-is (app store text, changelog entry, customer email). Written to `releaseNotes.file` when configured.
2. The **announcement** for `chat`, per `rules/announcement.md`. Post it only when `chat.post` is `true`; otherwise hand the user a single copy-pasteable block and tell them where to send it.

Close by pointing at the runbook's own post-release steps if it has any.

## Failure handling

If any deploy job fails — a lint/type/test gate, a migration step, a service-stability wait, a publish step — **stop**. Surface the failing job and the relevant log lines, delete the step-3 tags (§5), and point at the runbook's rollback and gotchas sections. A failed migration blocking the deploy is correct behaviour, not a flake. Re-cut only after a fix lands.

## Rules

- `rules/first-run-setup.md` — the zero-config interview: what to probe, what to ask, what to write.
- `rules/repo-settings-audit.md` — verify GitHub merge strategy per branch (squash on trunk, merge commits on release tiers) and propose fixes.
- `rules/release-notes.md` — technical notes vs. public human-readable notes; how each is derived.
- `rules/announcement.md` — the chat announcement structure and its formatting invariants.
- `rules/integrations.md` — the tracker/chat adapter contract and how to satisfy it per provider.
