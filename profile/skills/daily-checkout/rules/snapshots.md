---
title: Rolling daily snapshots
impact: MEDIUM
tags: [state, recall, offline-cache]
---

# Rolling daily snapshots

After both messages send successfully, persist the day locally so later questions — "what did I do yesterday", "summarize the last couple of days", "recap" — can be answered without re-querying GitHub or asking the user to paste links.

## Location and rotation

- **Directory** — `~/.claude/arsenal/snapshots/<project>/`, one folder per project. Create it with `mkdir -p` on first run.
- **Filename** — `<YYYY-MM-DD>.md`.
- **Window** — keep at most the **2** most recent files per project. After writing today's, list the folder and remove every other `*.md`. ISO filenames sort lexicographically, so `ls | sort | head -n -2` is the set to delete.
- The snapshot dir lives under `~/.claude/arsenal/`, deliberately outside this skill's own directory, so the skill stays stateless and copyable and its data never lands in a git repo.

## Content

One Markdown file with everything needed to reconstruct the day without external lookups:

```markdown
---
date: <YYYY-MM-DD>
weekday: <Weekday>
project: <project>
ticket_ids: [<KEY>, <KEY>]
pr_urls:
  - <url>
commit_urls:
  - <url>
reviewed_prs:
  - <url>
---

# Daily snapshot — <Weekday MM/DD>

## Daily update (as sent)

<verbatim copy of the message that was sent>

## Tickets worked on

<verbatim copy of the second message>

## PR details

### <ticket key or "No ticket"> — <PR title>
- Repo: <repo>
- PR: <url>
- State: <OPEN | MERGED>
- Created: <ISO timestamp>
- Summary: <1–2 lines from the PR body>
```

The **PR details** section is what makes recall useful — it preserves per-PR title, repo, state, and summary, so a later "what did I do yesterday?" produces a real answer instead of re-quoting bullets. The `reviewed_prs` list is what dedups reviews across days.

## Answering "what did I do?"

When the user asks for a recap **without** providing links:

1. `ls ~/.claude/arsenal/snapshots/<project>/` to see which days are on hand. Resolve the project the same way as invocation; default to `defaultProject`.
2. Read the matching file(s) and answer from them. Do **not** re-run discovery.
3. If the requested day is outside the window, say so plainly — it rotated out, and answering would mean re-querying GitHub. Offer to do that.

Snapshots are an offline cache, not a source of truth. If the user asks about *today* and today's snapshot doesn't exist yet (they haven't run `sleep`), fall back to normal discovery.

## Rules

1. Write the snapshot only after both messages send successfully.
2. Keep 2 files per project; delete the rest right after writing.
3. Snapshots live under `~/.claude/arsenal/snapshots/`, never inside the skill directory or a git repo.
4. For a recap request, read snapshots first and only re-query when they can't answer — and say which you did.
