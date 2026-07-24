---
title: Importing project skills into a repository
impact: MEDIUM
tags: [install, project, config]
---

# Importing project skills into a repository

`project/skills/*` install into a specific repository's `.claude/skills/`, because they act on that repo and their config is committed beside them so every contributor's agent reads the same thing.

## Pick and verify the target

Ask for an absolute path, then verify:

```bash
git -C "<target>" rev-parse --show-toplevel
```

Not a git repo → say so and ask again. Use the toplevel it reports, not the path as typed, so the skills land at the repo root even if the user pointed at a subdirectory.

## Copy

```bash
mkdir -p "<repo>/.claude/skills"
cp -RL project/skills/<name> "<repo>/.claude/skills/"
```

Same per-skill rules as the profile half: new → copy; identical → skip; differs → ask, back up, replace wholesale. Same trailing-slash trap too — no `/` on the source, and verify each skill landed as its own directory with a `SKILL.md` inside.

The `*.config.example.json` files ship **inside** each skill directory. Leave them there — they're the template the skill reads when bootstrapping, and they contain no data.

## These are committed files

The skills and their config land in the repo's working tree, which means they show up in `git status` and belong in a commit. Say so explicitly, and leave the committing to the user — it's their repo, their PR, and possibly their team's review.

Two things must **not** be committed, so check the repo's `.gitignore` and mention what's missing:

- `.claude/settings.local.json` — machine-local overrides.
- Anything under `.claude/` that the repo's own conventions exclude.

The skill config files (`release.config.json`, `pr-ritual.config.json`) **are** meant to be committed — that's the point of putting them in the repo. But they can hold a chat channel and a tracker space, so tell the user what's in them before they commit, and let them decide.

## Bootstrap the config

After copying, offer both paths and let the user choose:

1. **Now** — run the release skill's first-run setup (`.claude/skills/release/rules/first-run-setup.md`) against this repo: probe branches, workflows, tags, and the tracker convention, ask what's left, write `.claude/release.config.json` and the runbook. Best done now while the context is fresh.
2. **Later** — the first `/release` in that repo runs setup automatically.

Same for `post-pr-ritual`: its config is written on first use, or now if the user prefers.

## Rules

1. Verify the target is a git repo and use its toplevel.
2. Same copy semantics as the profile half; never merge two versions of a skill.
3. Tell the user these files are now uncommitted changes in their repo — don't commit for them.
4. Name what the config files will contain before they're committed.
5. Offer config bootstrap now-or-later; don't force an interview the user didn't ask for.
