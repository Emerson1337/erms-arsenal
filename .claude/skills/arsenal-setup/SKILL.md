---
name: arsenal-setup
description: Install this arsenal of Claude Code presets onto the current machine — profile skills and global config into ~/.claude, project skills into a chosen repository, plus a first project entry in the local registry. Use when the user has just cloned the arsenal repo and says "set up", "install the arsenal", "install my presets", "/arsenal-setup", or asks to get their skills and config onto a new machine or account. Idempotent and re-runnable; `--check` reports what it would do without writing anything.
argument-hint: [--check | profile | project | registry]
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
---

# Arsenal setup

Install the presets in this repository onto the current machine. Safe to re-run: it detects what's already installed, backs up anything it replaces, and never silently discards local customisation.

Run from the root of the arsenal clone. If `profile/` and `project/` aren't present in the working directory, say so and stop — you're in the wrong place.

## What goes where

| Source | Destination | Why there |
| --- | --- | --- |
| `profile/skills/*` | `$HOME/.claude/skills/` | invoked from any directory, work on any repo |
| `profile/CLAUDE.md` | `$HOME/.claude/CLAUDE.md` (merged) | global working preferences |
| `profile/settings.json` | `$HOME/.claude/settings.json` (merged) | permissions, statusline, env |
| `profile/statusline-command.sh` | `$HOME/.claude/statusline-command.sh` | referenced by settings |
| `profile/templates/projects.example.json` | `$HOME/.claude/arsenal/projects.json` | local registry — never committed anywhere |
| `project/skills/*` | `<target-repo>/.claude/skills/` | act on one repo; config is committed beside them |

`$HOME/.claude` means the active config dir — honour `CLAUDE_CONFIG_DIR` when it's set, so a sandboxed test install doesn't touch the real one:

```bash
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
```

## Modes

| Argument | Behaviour |
| --- | --- |
| *(none)* | Full run: detect → choose → profile → project → registry → summary |
| `--check` | Dry run. Report every action it *would* take. **Writes nothing** — no files, no backups, no directories. |
| `profile` | Profile skills and global config only |
| `project` | Project skills into a repo only |
| `registry` | Registry interview only |

## 1. Detect

Before asking anything, report the current state — the user decides better with facts:

```bash
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
ls "$CONFIG_DIR" 2>/dev/null
ls "$CONFIG_DIR/skills" 2>/dev/null
test -f "$CONFIG_DIR/settings.json" && echo "settings.json exists"
test -f "$CONFIG_DIR/CLAUDE.md" && echo "CLAUDE.md exists"
test -f "$CONFIG_DIR/arsenal/projects.json" && echo "registry exists"
```

For each skill in `profile/skills/`, classify it as **new**, **identical** (`diff -rq` clean), or **differs**. Show the counts, and name the ones that differ — those are the only interesting ones.

## 2. Choose

One `AskUserQuestion` round, options driven by what step 1 found:

1. **Profile skills** — all / only new ones / pick from a list / skip.
2. **Global config** — merge `CLAUDE.md` + `settings.json` + statusline / skip.
3. **Project skills** — into which repository? Offer to skip. Ask for an absolute path and verify it's a git repo.
4. **Registry** — set up a first project now, or later.

For any skill that **differs**, ask per skill: keep mine, take the arsenal's (backed up), or show the diff first. Never overwrite a differing file without a decision.

## 3. Profile install

Details in `rules/profile-install.md`. In short: back up first, copy skills, merge `CLAUDE.md` by section, merge `settings.json` by union, resolve the statusline path to this machine's home.

## 4. Project install

Details in `rules/project-install.md`. Copy `project/skills/*` into `<repo>/.claude/skills/`, then offer to run the release skill's first-run setup immediately or defer it to the first `/release`.

## 5. Registry

Details in `rules/registry-interview.md`. Create `$CONFIG_DIR/arsenal/projects.json` with at least one project so `daily-checkout` works on its first invocation.

## 6. Summary

Report, in this order:

- **Installed** — what landed where.
- **Skipped** — what and why (already identical, user declined, source missing).
- **Backed up** — the backup directory path.
- **Needs you** — anything requiring action outside this repo: MCP connectors the workflow skills expect (chat, tracker, GitHub) must be connected in the client; `gh auth login` if `gh auth status` fails; a restart of the CLI to pick up new skills.
- **Verify** — the commands to confirm it worked (see the repo README's verification section).

Never claim something installed that you skipped, and never report success for a step whose write failed.

## Rules

- `rules/profile-install.md` — backups, per-skill decisions, `CLAUDE.md` and `settings.json` merge semantics, statusline path.
- `rules/project-install.md` — importing project skills and bootstrapping their config.
- `rules/registry-interview.md` — the questions, and what a valid registry entry looks like.
