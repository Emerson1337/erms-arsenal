---
title: Tracker adapters
impact: MEDIUM
tags: [integrations, tracker, mcp, adapters]
---

# Tracker adapters

The ritual needs three tracker operations. `tracker.type` decides who implements them.

| Operation | Degrades to |
| --- | --- |
| `resolve-ticket` (key → id/url) | key parsed from the PR title or branch name |
| `comment-on-ticket` | print the comment text and say where to paste it |
| `move-status` | tell the user which status to set by hand |

**Tool names drift between connector versions.** Confirm the exact name of a loaded MCP tool before calling it rather than trusting a name written here — a comment tool may be exposed as `create_comment` or `create_task_comment` depending on version. If the server isn't loaded, say so once and degrade; never retry name variants.

## Ticket-key extraction (all providers)

From the PR title or branch name, using `tracker.prefix`:

```bash
gh pr view <n> --json title,headRefName -q '.title + " " + .headRefName' \
  | grep -oE '<tracker.prefix>[0-9]+' | head -1
```

No key found and `tracker.type` isn't `none` → run step 1 only, and say the ticket link is missing rather than guessing one.

## `clickup`

- Ticket keys work directly as `task_id` — no internal-id lookup needed.
- **Comment** — the ClickUp create-comment tool with the rendered `commentTemplate`.
- **Status** — the update-task tool with `status` set to `reviewStatus` verbatim (`rules/status-vocabulary.md`).
- `tracker.space` / `tracker.list` are for building URLs and for error messages that name the board.

## `jira`

- **Comment** — the Jira MCP add-comment tool, or `POST /rest/api/3/issue/<key>/comment` when credentials already exist in the environment.
- **Status** — Jira moves by *transition*, not by status name: list the issue's available transitions, find the one whose target matches `reviewStatus`, and execute that transition id. If no transition matches, that's a config or workflow problem — surface it, don't force it.

## `linear`

- **Comment** — the Linear MCP comment tool.
- **Status** — set the issue's state to the one named by `reviewStatus`. Linear state names are per-team; a mismatch is reported, never guessed.

## `github`

Ticket = an issue in the same repo, keys are `#<n>`:

```bash
gh issue comment <n> --repo <slug> --body '<rendered commentTemplate>'
```

Status is a label or project field. When `reviewStatus` is a label: `gh issue edit <n> --add-label '<reviewStatus>'`. When it's a project field, say what needs setting rather than guessing the project schema.

## `none`

Step 1 only. Assign the PR, say there's no tracker configured, and stop. No prompting for one.

## Rules

1. Only this file names providers.
2. Verify an MCP tool's real name in-session before calling it.
3. A missing integration degrades to telling the user what to do by hand — never to silence.
4. Send status values verbatim; never invent a variant.
