---
name: post-pr-ritual
description: Run the standing post-PR handoff ritual after a pull request is opened in this repository — assign the PR to its owner on GitHub, comment the PR URL on the linked ticket, and move that ticket to the review status. Use this every time you open (or confirm "PR is open" for) a PR in a repo that has `.claude/pr-ritual.config.json`, or when the user says "PR is open", "follow our standards", "do everything we usually do" around a ticket — no explicit invocation needed. Skip when the PR is a draft, the ticket is on hold, or the user says otherwise.
---

# Post-PR Ritual

After a PR is opened, run this handoff so GitHub and the tracker stay in sync. The steps are independent — run them in parallel.

## Configuration

Read config before doing anything, in this order:

1. `.claude/pr-ritual.config.json` in the repo (committed) — the authority.
2. No such file, but `.claude/release.config.json` exists → reuse its `tracker` block and ask only for what's missing (`assignee`, `reviewStatus`).
3. Neither → run the first-run interview below.

```json
{
  "assignee": "",
  "reviewStatus": "",
  "tracker": {
    "type": "clickup|jira|linear|github|none",
    "prefix": "",
    "commitPattern": "",
    "urlTemplate": "",
    "space": "",
    "list": ""
  },
  "commentTemplate": "PR open for review: {url}"
}
```

Every field is empty in the template. **An empty field means "not configured" — ask, never assume.** Do not carry an assignee, status name, or ticket prefix over from another repo or another session.

### First-run interview

1. **Assignee** — the GitHub handle the PR should be assigned to. Infer the candidate from `gh api user --jq .login` and confirm.
2. **Tracker** — type, ticket-key prefix (offer what `git log --pretty=%s -200 | grep -oE '^\[?[A-Z][A-Z0-9]+-[0-9]+' | sort | uniq -c | sort -rn | head` shows), and the ticket URL template.
3. **Review status** — the exact status string this board uses for "someone else should look at this now". Ask for it verbatim, including case and spacing — see `rules/status-vocabulary.md` for why exactness matters. If the tracker MCP tool can list the board's statuses, list them and let the user pick instead of typing.
4. Write the config, then run the ritual.

## When to apply

Triggers automatically when:

- You've just opened a PR in a repo that has this skill installed and configured.
- The PR title or branch name contains a key matching `tracker.prefix`.
- The user says "PR is open" / "PR opened" / "follow our standards" / "do everything we usually do" around a ticket.

Skip when:

- The PR is a draft — see `rules/skip-when-draft.md`.
- The user says the ticket is on hold, blocked, or shouldn't be reviewed yet.
- The PR has no linked ticket and `tracker.type` isn't `none` — then only step 1 applies.

## The steps

Run all of them, in parallel — they share no state. See `rules/parallel-execution.md`.

### 1. Assign the PR

```bash
gh pr edit <pr-number> --add-assignee <assignee>
```

Prefer `mcp__github__update_pull_request` with `assignees: ["<assignee>"]` when the GitHub MCP server is loaded — see the MCP-over-`gh` preference in the global `CLAUDE.md`.

### 2. Comment the PR URL on the ticket

Keep it short and identical every time, so the ticket history reads cleanly. `commentTemplate` with `{url}` substituted; the default is:

```
PR open for review: <pr-url>
```

The exact tool depends on `tracker.type` — see `rules/integrations.md`.

### 3. Move the ticket to the review status

Send `reviewStatus` **exactly** as configured. If the call rejects the value, do not retry with a variant — see `rules/status-vocabulary.md`.

## Confirming back

One tight line per step, e.g.:

> PR #<n> → assigned `<assignee>`, URL commented on `<ticket>`, ticket moved to `<status>`.

Don't restate what the PR did — the user just read that. Confirm the handoff, nothing more.

## Why this ritual exists

Without it: teammates can't tell the ticket is ready for review because its status still says in-progress; the PR sits unowned on review dashboards; and the ticket has no trail back to the PR, so future tracebacks go through `git log` instead of ticket history. Running all three keeps GitHub and the tracker in lockstep with zero manual prompts — the cheapest available answer to "where is this work?".

## Rules

- `rules/parallel-execution.md` — why the steps run in one turn.
- `rules/status-vocabulary.md` — exact status strings, and what to do when one is rejected.
- `rules/skip-when-draft.md` — draft PRs get step 1 only.
- `rules/integrations.md` — tracker adapters.
