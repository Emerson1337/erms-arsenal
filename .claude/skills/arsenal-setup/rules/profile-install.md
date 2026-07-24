---
title: Installing the profile half
impact: HIGH
tags: [install, backup, settings, merge]
---

# Installing the profile half

Everything here writes into `CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"`. Under `--check`, do the reads and report the intended actions — but create nothing, not even the backup directory.

## Back up first

One timestamped directory per run, so a bad install is one `cp` away from undone:

```bash
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP="$CONFIG_DIR/arsenal/backups/$STAMP"
mkdir -p "$BACKUP"
```

Copy any existing file into it **before** modifying it: `CLAUDE.md`, `settings.json`, `statusline-command.sh`, and each skill directory you're about to replace. Report the path in the summary.

## Skills

```bash
mkdir -p "$CONFIG_DIR/skills"
cp -RL profile/skills/<name> "$CONFIG_DIR/skills/"
```

> **No trailing slash on the source.** `cp -R src/ dest/` copies the *contents* of `src` on BSD/macOS `cp`, so `profile/skills/<name>/` splatters `SKILL.md` and `rules/` straight into `skills/` instead of creating `skills/<name>/`. Iterating over `profile/skills/*/` in a shell loop gives you paths *with* trailing slashes — strip them (`"${d%/}"`) before copying. The verification step below catches this, which is exactly why it exists.

- **New** → copy.
- **Identical** (`diff -rq` clean) → skip silently; say so only in the counts.
- **Differs** → the decision from step 2. On "take the arsenal's": back up the existing directory, then replace it wholesale. Don't merge two versions of a skill — a half-merged skill is worse than either version.
- Some source skills may be symlinks on the machine that produced them. Copy with `-L` (or verify no symlinks survive: `find "$CONFIG_DIR/skills" -type l`), or the destination gets links pointing at paths that don't exist here.
- After copying, verify every installed skill landed as its own directory containing a `SKILL.md`:
  ```bash
  for d in "$CONFIG_DIR"/skills/*/; do
    test -f "$d/SKILL.md" || echo "BROKEN: $d has no SKILL.md"
  done
  ```
  A `skills/rules/` directory or a bare `skills/SKILL.md` is the trailing-slash mistake above — clean it up and re-copy.

## `CLAUDE.md` — merge by section

Never overwrite. The user's existing file may hold preferences this arsenal knows nothing about.

1. Read both files.
2. Split each into `##` sections.
3. For each arsenal section: if a section with that heading exists, **leave the user's version alone** and note the difference in the summary. If it doesn't exist, append it.
4. Show the resulting diff and get an explicit go before writing.

Rationale: an existing section is a deliberate choice by whoever set that machine up. Appending is additive and safe; replacing is not.

## `settings.json` — merge by union

Read both as JSON. Never write a whole-file replacement.

- `permissions.allow` / `deny` / `ask` → **union**, order preserved, duplicates dropped. If the same pattern appears in the user's `allow` and the arsenal's `deny`, keep the **more restrictive** one and flag it — silently loosening a permission is the one unacceptable outcome here.
- `env` → merge keys; on conflict keep the user's value and report it.
- Scalar keys the user already has (`tui`, `voice`, model settings…) → leave theirs.
- Scalar keys they don't have → add the arsenal's.
- `enabledPlugins`, `extraKnownMarketplaces` → merge keys, keep existing values.
- **`statusLine.command`** — the arsenal template ships the placeholder `__CONFIG_DIR__`, which **must** be substituted before writing. The path is absolute and cannot use `~` or `$HOME`: Claude Code doesn't expand them. Write the literal resolved path for *this* machine:
  ```bash
  # __CONFIG_DIR__ → the real path, e.g.
  echo "sh $CONFIG_DIR/statusline-command.sh"
  ```
  Only set it if the user has no `statusLine` already. Grep the merged result for `__CONFIG_DIR__` before writing — a surviving placeholder means a broken statusline.

Validate before and after: `python3 -m json.tool < <file> > /dev/null`. If the merged result doesn't parse, restore from the backup and report the failure — never leave a broken `settings.json` behind, since it can stop the CLI from starting.

Show the merged result as a diff and get a go before writing.

## Statusline script

```bash
cp profile/statusline-command.sh "$CONFIG_DIR/statusline-command.sh"
chmod +x "$CONFIG_DIR/statusline-command.sh"
```

It reads session JSON from stdin and shells out to `git`. It needs `jq` — check with `command -v jq` and mention it in "Needs you" if it's missing.

## Registry file

```bash
mkdir -p "$CONFIG_DIR/arsenal"
cp profile/templates/projects.example.json "$CONFIG_DIR/arsenal/projects.json"
```

Only when it doesn't already exist. If it does, leave it and hand off to `rules/registry-interview.md` to add a project. Never overwrite a registry — it's the only copy of that data and it exists nowhere in git.

## Rules

1. Back up before touching anything; report the backup path.
2. `--check` writes nothing at all.
3. `CLAUDE.md` merges by appending missing sections only.
4. `settings.json` unions permission lists, keeps the user's values on conflict, and never loosens a restriction.
5. Validate JSON before and after; restore from backup on a parse failure.
6. Statusline path is literal and absolute — no `~`, no `$HOME`.
7. Never overwrite an existing registry.
