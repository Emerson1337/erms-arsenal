---
name: arsenal-sync
description: Port what changed in this machine's Claude Code setup (skills, rules, hooks, global CLAUDE.md, settings) back into this arsenal repository, rewritten in generic form so the public repo never carries names, IDs, or paths. Use when the weekly sync job runs it headless, or when the user says "sync my arsenal", "push my skills to the arsenal", or "/arsenal-sync". Edits files in this repository only; the caller commits, runs the leak check again, and opens the PR.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Arsenal sync

The machine is the source of truth for what the user actually works with. This skill brings the arsenal up to date with it, one direction only: **machine → repository**. It never writes into the machine's config.

Run from the root of the arsenal clone. `CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"`.

## What maps where

| On the machine | In the arsenal |
| --- | --- |
| `$CONFIG_DIR/CLAUDE.md` | `profile/CLAUDE.md` |
| `$CONFIG_DIR/settings.json` | `profile/settings.json` (structure only — see below) |
| `$CONFIG_DIR/rules/*.md` | `profile/rules/` |
| `$CONFIG_DIR/hooks/*` | `profile/hooks/` |
| `$CONFIG_DIR/statusline-command.sh` | `profile/statusline-command.sh` |
| `$CONFIG_DIR/skills/<name>` | `project/skills/<name>` when that directory already exists, otherwise `profile/skills/<name>` |

Skip, always:

- Anything listed in `scripts/sync-ignore.txt` (one glob per line, relative to `$CONFIG_DIR`).
- Personal data inside a skill: `snapshots/`, filled `*.json` configs, caches, logs.
- Skills the machine has but that came from an account or plugin sync (a `skills/synced/` tree, plugin caches).

Never delete anything from the repository because the machine lacks it. A skill missing locally may simply not be installed on this machine.

## 1. Find the drift

For every mapped pair, compare with `diff -rq` (follow symlinks on the machine side). Classify each as **new**, **changed**, or **same**. Ignore whitespace-only differences. Work only on new and changed items.

## 2. Port each change in generic form

The repository is public and generic by contract (see the README). Bring over the *intent* of each change, not its personal values.

- **Identifiers become config or placeholders.** GitHub handles, org and repo names, ticket keys, tracker space or list IDs, chat channel or DM IDs, emails, hostnames, workstation names, and absolute home paths never land in the repo. Follow the pattern the arsenal already uses: values a skill needs at run time go in its `*.config.example.json` template with an empty value (or `<placeholder>`), and the skill text reads them from the filled config, which lives outside the repo. Mention the new field in the skill's first-run interview.
- **Product- or employer-specific instructions get generalized or dropped.** Keep the rule if it is useful anywhere ("every PR with a visible change carries highlighted screenshots"); strip the parts that only apply to one codebase (its start command, its routes, its internal tool names). If nothing generic remains, leave it out and list it in the summary as kept local.
- **Paths in settings and hooks use `__CONFIG_DIR__`**, never a resolved path. The setup skill substitutes it at install time.
- **`settings.json` carries structure, not machine state.** Port new hooks, permission patterns, env keys, and plugin entries. Leave out anything machine- or account-specific (model choices tied to an account, tokens, local tool paths).
- **Reference skills** (the `frontend-*`, `owasp-security-check`, `skill-writing-best-practices` docs) are imported verbatim; copy them as they are.
- **Keep the house style.** Match the surrounding skill's structure, headings, and tone. Don't rewrite text that didn't change.

When a new skill or rule is added, update the README's "What's inside" tables and the setup skill's mapping if it introduces a new kind of file.

## 3. Check for leaks

```bash
bash scripts/check-generic.sh
```

Fix every hit by generalizing the text. Never weaken or delete a check to make it pass. Re-run until it prints clean.

## 4. Write the summary

Write a short Markdown summary to the path in `$ARSENAL_SYNC_SUMMARY` (or print it if the variable is unset), in this shape:

```markdown
### Synced
- `profile/skills/<name>` — what changed, in one line

### Kept local
- `<path>` — why it stays off the repo

### Needs a look
- anything you were unsure how to generalize
```

Omit an empty section. If nothing changed, write `Nothing to sync.` and make no edits.

## Rules

1. One direction: machine → repository. Never write into `$CONFIG_DIR`.
2. No names, IDs, handles, hosts, or absolute paths in the repo — move them to config templates.
3. Never delete repo content because the machine lacks it.
4. `scripts/check-generic.sh` must pass before you finish.
5. Don't commit, push, or open a PR — the caller does that after its own check.
