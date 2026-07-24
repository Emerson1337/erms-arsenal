---
title: Tracker and chat adapters
impact: MEDIUM
tags: [integrations, tracker, chat, mcp, adapters]
---

# Tracker and chat adapters

The release procedure never names a provider. It calls the operations below, and the config's `tracker.type` / `chat.type` decide who implements them. An operation with no implementation **degrades to composing output for the user** — it never fails the release and never blocks a tag.

## The contract

| Operation | Used by | Degrades to |
| --- | --- | --- |
| `resolve-ticket-keys` | notes, announcement | keys parsed from commit subjects |
| `ticket-url` | notes, announcement | plain key, unlinked |
| `ticket-title` | notes (nicer than a raw subject) | the commit subject as-is |
| `format-message` | announcement | plain text |
| `send-message` | announcement | hand the user a copy-pasteable block |

**Tool names drift between connector versions.** Before calling an MCP tool, confirm the exact name that's actually loaded in this session rather than trusting a name written here — e.g. a comment tool may be exposed as `create_comment` or `create_task_comment` depending on the version. If the expected server isn't loaded at all, say so once and degrade; don't retry name variants.

---

## Tracker: key extraction (all providers)

Keys always come from the commit history, never from an API call:

```bash
git log --pretty=%s <previous-tag>..<this-tag> | grep -oE '<tracker.prefix>[0-9]+' | sort -u
```

`tracker.commitPattern` records the convention (commonly a bracketed prefix on the subject line). Empty `prefix` → skip ticket handling entirely; the notes just use commit subjects.

## `tracker.type: clickup`

- **Ticket URL** — `tracker.urlTemplate` with the key substituted. When `tracker.space` is set the template usually embeds it.
- **Ticket title** — the ClickUp MCP get-task tool accepts the human key directly (no need to resolve an internal id first). One call per key; skip if the server isn't loaded.
- Release flow needs **reads only**. Status moves belong to the PR/review workflow, not to cutting a release.

## `tracker.type: jira`

- **Ticket URL** — `tracker.urlTemplate` (`https://<host>/browse/<key>`).
- **Ticket title** — the Jira MCP tool if loaded, else `curl` against the REST API only if credentials already exist in the environment. Never prompt for a token during a release; degrade instead.

## `tracker.type: linear`

- **Ticket URL** — `tracker.urlTemplate`. Linear keys are `TEAM-<n>`, so the same extraction regex applies.
- **Ticket title** — the Linear MCP tool if loaded, else degrade.

## `tracker.type: github`

Issues in the same repo. Keys are `#<n>`:

```bash
gh issue view <n> --repo <slug> --json title,url
```

## `tracker.type: none`

Parse keys from commit subjects if a `prefix` happens to be set, otherwise use commit subjects verbatim. No network calls, no links. This is a fully supported configuration, not a fallback.

---

## `chat.type: slack`

- **Format** — Slack renderers differ by client and by the tool you send with, and getting this wrong is the most common defect in a release message. Before sending, confirm which flavour the loaded send tool expects:
  - **mrkdwn** (legacy): `*bold*`, `_italic_`, `<url|label>` links.
  - **standard Markdown**: `**bold**`, `_italic_`, and bare URLs that auto-unfurl.

  Single asterisks in a standard-Markdown context render as *italic*, not bold — that's the specific mistake to watch for.
- **Lists** — a bullet list needs a blank line **before** the first bullet and **after** the last. Without them the renderer doesn't recognise the markers, strips the dashes, and glues the following line onto the last bullet.
- **Send** — the Slack MCP send-message tool, targeting `chat.channelId` (an ID is more reliable than a name). Only when `chat.post` is true.
- Preserve the blank-line invariant from `rules/announcement.md` through formatting — it's the reason that rule exists.

## `chat.type: discord`

Standard Markdown, `**bold**`, no `<url|label>` syntax — put the label text and the bare URL on the same line. Send through whatever Discord tool is loaded; if none is, degrade. Untested in practice: verify the rendering on a throwaway message before trusting it for a release.

## `chat.type: none`

Compose the announcement and hand it over as a single copy-pasteable block. Never post anywhere. This is also what every provider does when `chat.post` is false — which is the default and the recommended setting.

## Rules

1. The procedure calls operations; only this file names providers.
2. Verify an MCP tool's real name in-session before calling it; don't guess variants.
3. A missing integration degrades to hand-over. It never fails a release and never leaves a tag in an inconsistent state.
4. Never post to chat unless `chat.post` is true.
5. Confirm the renderer's markup flavour before formatting a message for it.
