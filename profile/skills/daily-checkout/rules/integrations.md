---
title: Chat and tracker adapters
impact: MEDIUM
tags: [integrations, chat, tracker, mcp, adapters]
---

# Chat and tracker adapters

The workflow never names a provider. It needs four operations; `chat.type` and `tracker.type` in the project's registry entry decide who implements them.

| Operation | Degrades to |
| --- | --- |
| `send-message` | print both messages as copy-pasteable blocks and tell the user where to send them |
| `read-recent` (style reference + dedup) | read the last snapshot file instead |
| `ticket-url` | plain ticket key, unlinked |
| `ticket-title` | the PR title with its `feat:`/`fix:` prefix stripped |

**Tool names drift between connector versions.** Confirm the exact name of a loaded MCP tool before calling it instead of trusting a name written here. If the server isn't loaded, say so once and degrade — never retry name variants, and never silently skip sending.

## Chat: `slack`

- **Send** — the Slack MCP send-message tool, targeting `chat.channelId`. IDs beat names: a name can resolve to the wrong channel or fail on a DM.
- **Format** — see `rules/message-formatting.md`. Confirm whether the send tool takes standard Markdown or legacy mrkdwn before composing; the bold syntax differs and getting it wrong is the most common defect here.
- **Read-recent** — the read-channel tool with a limit of 10–20, to find the last daily update for style and dedup.
- Two separate messages, in order: detailed update first, tickets list second. Not one combined message.

## Chat: `discord`

Standard Markdown. No `<url|label>` syntax — put label text and the bare URL on the same line. Send through whichever Discord tool is loaded; if none is, degrade. Untested in practice — verify rendering on a throwaway message first.

## Chat: `none`

Print both messages as copy-pasteable blocks, in order, and say where they go. Nothing is sent. This is a valid permanent configuration.

## Tracker: `clickup`

- **Ticket URL** — `tracker.urlTemplate` with the key substituted; the template usually embeds `tracker.space`.
- **Ticket title** — the get-task tool accepts the human key directly, no internal-id lookup needed. Prefer the PR title when the ticket title is vaguer — the reader wants to know what shipped.

## Tracker: `jira` / `linear`

`tracker.urlTemplate` for links. Titles from the respective MCP tool when loaded, otherwise degrade to PR titles. Never prompt for credentials mid-checkout.

## Tracker: `github`

Issues in the same repo; keys are `#<n>`. `gh issue view <n> --repo <org>/<repo> --json title,url`.

## Tracker: `none`

Every block is a `[No ticket]` block titled from the PR or commit subject. The second message lists one bullet per item. Fully supported — plenty of projects work this way.

## Rules

1. Only this file names providers; the workflow calls operations.
2. Verify an MCP tool's real name in-session before calling it.
3. A missing integration degrades to hand-over — never to silence.
4. Send to the configured channel only; ID over name.
