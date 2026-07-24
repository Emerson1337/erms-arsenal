---
name: daily-checkout
description: Compose and send an end-of-day checkout message summarizing the day's PRs, reviews, commits, tickets, and meetings — fully automated per project. Use when the user says "sleep", "sleep <project>", "execute the protocol sleep", "run the sleep protocol", "daily update", "daily checkout", "checkout message", "EOD update", "send my daily", or asks to summarize what they completed today. Auto-discovers today's work from the project's repos, composes the daily update plus a follow-up tickets-worked-on list, and sends both to the project's configured chat channel. Also persists a rolling snapshot of each day under the arsenal data dir so later "what did I do yesterday / the last couple of days" questions can be answered without the user pasting links.
---

# Daily Checkout — "Protocol Sleep"

Compose and send the user's end-of-day checkout. Two messages per day, in order:

1. **Daily Updates** — the detailed per-ticket block message (work grouped by ticket, with bullets).
2. **Tickets worked on** — a plain bullet list of ticket number + title, for time tracking.

Send **both** unless the user says otherwise.

## Configuration

Everything project-specific lives in `~/.claude/arsenal/projects.json` — never in this skill. Read it first:

```bash
cat ~/.claude/arsenal/projects.json
```

Each project entry provides:

| Field | Meaning |
| --- | --- |
| `repos[]` | `{ name, path }` — local clone paths, so `gh`/`git` run in the right cwd |
| `github.org` | for building PR and commit URLs |
| `tracker` | `{ type, prefix, urlTemplate, space }` — how tickets are identified and linked |
| `chat` | `{ type, channelId, channel }` — where the messages go |
| `defaultProject` | top-level key: which project a bare `sleep` means |

**If the file is missing or has no projects, run the interview below before anything else.** Do not guess paths, channels, or ticket prefixes, and do not fall back to a project you remember from another session.

### First-run interview

Ask for, in this order, then write the entry to `~/.claude/arsenal/projects.json` and continue on the same turn:

1. **Project name** — the keyword typed after `sleep`.
2. **Repos** — each repo's name and local clone path. Verify each path exists and is a git repo (`git -C <path> rev-parse --show-toplevel`).
3. **GitHub org/owner** — infer it from a repo's remote (`git -C <path> remote get-url origin`) and confirm rather than asking cold.
4. **Chat destination** — which channel or DM the update goes to, and its ID. Explain that an ID is more reliable than a name.
5. **Tracker** — type, ticket prefix, and ticket URL template. Offer what the commit log shows: `git -C <path> log --pretty=%s -200 | grep -oE '^\[?[A-Z][A-Z0-9]+-[0-9]+' | sort | uniq -c | sort -rn | head`. If the project has no tracker, say so — untracked work is reported as `[No ticket]` blocks.
6. Whether this project should become the `defaultProject` for a bare `sleep`.

## Invocation

- `sleep <project>` → that project.
- Bare `sleep` → `defaultProject`, and **say which project you're running for** in a one-line preamble so the user can correct you.
- An unregistered project name → run the interview for it, then proceed.

## Workflow

The user typing `sleep <project>` is the entire input. Do all of this on one turn.

### 1. Resolve the project

From the registry. One-line preamble naming the project.

### 2. Discover today's authored PRs

Per repo, in parallel (independent Bash calls in one message):

```bash
gh pr list --author "@me" --state all --limit 20 \
  --json number,title,url,createdAt,updatedAt,state,body \
  --search "updated:>=<TODAY>"
```

### 3. Discover direct commits to the default branch

Critical: commits pushed straight to the default branch have no PR and are otherwise invisible, so they get silently dropped. Per repo, in parallel:

```bash
git -C <path> fetch --quiet origin && \
git -C <path> log origin/HEAD \
  --author="$(git -C <path> config user.email)" \
  --since="<TODAY> 00:00" --until="<TODAY> 23:59" \
  --pretty=format:'%H%x09%s%x09%aI'
```

Then filter out commits already covered by a PR from step 2:

- **Squash merges** end with `(#<n>)` — drop when `<n>` is a PR you already have.
- **Merge commits** start with `Merge pull request #<n>` — same.
- What's left is a real direct commit. Extract a ticket key from the subject when it matches `tracker.prefix`, else file it under `[No ticket]`. Its link line becomes `Commit: https://github.com/<org>/<repo>/commit/<sha>`.

If the user mentions work that's neither in a PR nor on the default branch (a commit on a feature branch with no PR yet), ask which repo/branch and resolve it with `git log`.

### 4. Discover PRs reviewed today

Code review is real work and is invisible to the steps above. **Required, not optional.** Per repo, in parallel:

```bash
gh pr list --search "reviewed-by:@me merged:>=<TODAY>" --state merged --limit 30 \
  --json number,title,author,url
gh pr list --search "reviewed-by:@me updated:>=<TODAY>" --state open --limit 30 \
  --json number,title,author,url
```

Exclude the user's own PRs (already counted as authored work) and anything a prior day's snapshot already reported. Collapse the rest into one `[No ticket] - PR reviews (N PRs across <repos>)` block, one compact line per PR, marking still-open ones "(open)" and prefixing cross-repo ones with the repo name. Add a matching line to the second message so review time gets logged.

### 5. Filter

- **Include** — anything created today.
- **Include** — PRs merged today but created earlier, *only if* the prior day's checkout didn't already cover them (dedup against the snapshot, step 8).
- **Include** — direct commits from step 3 not represented by a PR.
- **Exclude** — PRs closed without merge. Abandoned work doesn't belong in a checkout.

### 6. Group by ticket

Multiple PRs sharing a ticket collapse into **one** block with a multi-link `PRs:` line. Take the key from the PR title, the commit subject, or the PR body's ticket link. A direct commit sharing a ticket with a PR folds into the same block with both link lines.

### 7. Compose both messages

Format below. Pull bullets from each PR body's `## Changes` / `## Summary` — stay close to the user's own wording. Don't invent detail: a thin PR body gets fewer bullets, not padding. For direct commits, derive 1–2 bullets from the subject plus `git show --stat <sha>`.

Read the last checkout from the snapshot dir (or the channel, if the chat provider supports reading) as a style reference and dedup source.

### 8. Send, snapshot, report

Send the daily update first, the tickets list second, through the project's chat provider (`rules/integrations.md`). Then write the snapshot (`rules/snapshots.md`). Return both message links.

## Format

```
:calendar: **Daily Updates - <Weekday MM/DD>**

**Ticket: <ticket-link|[<KEY>]> - <title>** :white_check_mark:

- <bullet>
- <bullet>

PR: <pr-url>

**Ticket: [No ticket] - <title>** :white_check_mark:

- <bullet>

PR: <pr-url>

_Meeting:_ <one-liner>
```

Second message:

```
**Tickets worked on - <Weekday MM/DD>** (for hours)

- <ticket-link|[<KEY>]> - <title>
- <ticket-link|[<KEY>]> - <title>
```

### Format rules

- **Header** — `:calendar: **Daily Updates - <Weekday MM/DD>**`, weekday spelled out, `MM/DD`, no year. Blank line after it.
- **Blank line between every block** — after each ticket block, before each `_Meeting:_` line. Without them the message renders as a wall of text.
- **Ticket line** — the entire line from `Ticket:` through the title sits inside one bold span, so the day's deliverables stand out to someone scanning. The checkmark emoji goes **outside** the bold.
  - Brackets go **inside** the link label (`<url|[KEY]>`), never wrapped around the link syntax — brackets adjacent to link syntax break the bold span.
  - Separate link from title with ` - `, not a colon.
  - Untracked work: `**Ticket: [No ticket] - <title>** :white_check_mark:`.
- **Bullets** — plain `-`, one per line, 2–4 per ticket. Backticks for code, paths, types, env vars. **A blank line before the first bullet and after the last** — see `rules/message-formatting.md`; this is the single most common rendering failure.
- **Link line** — `PR: <url>` (or `PRs: <url>, <url>`, or `Commit: <url>`), preceded by a blank line so it isn't glued to the last bullet.
- **Meetings / non-PR work** — after all ticket blocks, `_Meeting:_ <one-liner>` lines, each on its own line, each preceded by a blank line.
- **No footer.** The message ends with the last block. No "sent using", no attribution, no signature. The user is the author.
- **Second message** — one bullet per *ticket*, not per PR. Titles stripped of `feat:`/`fix:` prefixes.

### Bullet content

Written for a PM or teammate scanning the update, not a code reviewer.

- **First bullet states the goal** — what the ticket needed and why the work exists, in plain language. For verification work, lead with the acceptance criterion under test. For features and fixes, lead with the user-facing need or the problem.
- **Middle bullets say what was done**, at the outcome level: behaviour changes, not implementation mechanics. Skip lock hints, internal function names, CSS selectors, and module paths unless the detail *is* the story. One env var or table name a teammate would actually use is fine; a list of query hints is not.
- **Last bullet gives the result** — measured numbers, what passes, what merged, what's deferred. Concrete numbers beat adjectives.
- Prefer fewer, plainer bullets. Collapse a multi-commit PR to goal + outcome rather than one bullet per commit.
- No test plans, no screenshot sections, no PR-template boilerplate.
- For QA returns and reworks, lead with the failure cause so the reader understands why the rework exists.
- `[No ticket]` entries still get substantive bullets — these are usually incident triage, code review, tooling, credentials work, or research.

## Rules

- `rules/message-formatting.md` — the blank-line and bold-syntax failure modes, in detail.
- `rules/snapshots.md` — the rolling snapshot: location, rotation, content, and how to answer "what did I do yesterday".
- `rules/integrations.md` — chat and tracker adapters.

## Don'ts

- Don't add any footer — no "sent using", no AI attribution, no signature line.
- Don't send anywhere other than the project's configured channel unless explicitly told.
- Don't reflow bullets that are already tight in the PR description — reuse the user's wording where it fits.
- Don't draft when the user has already approved sending — send.
- Don't proceed on a remembered project config. The registry is the only source.
