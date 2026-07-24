---
title: Chat message formatting failure modes
impact: HIGH
tags: [chat, markdown, formatting]
---

# Chat message formatting failure modes

Two rendering bugs account for nearly every malformed checkout. Both are invisible in the composed text and only show up once the message is posted, where it's already been read.

## 1. Bold syntax depends on the renderer

Chat platforms accept different markup depending on the client *and* the tool used to send. Confirm which flavour the loaded send tool expects before composing:

| Flavour | Bold | Italic | Links |
| --- | --- | --- | --- |
| Standard Markdown | `**text**` | `_text_` | bare URL, auto-unfurled |
| Legacy mrkdwn | `*text*` | `_text_` | `<url\|label>` |

**The trap:** single asterisks in a standard-Markdown context render as *italic*, not bold. A message that looks emphatic in the source arrives limp. When the send tool documents standard Markdown, always use `**…**`.

If you're unsure which flavour applies, say so and use the one the send tool's own documentation states — don't split the difference.

## 2. Bullet lists need surrounding blank lines

A standard-Markdown renderer only recognises `-` as a list marker when the list is separated from surrounding text by blank lines. Without them:

- the dashes are stripped,
- the bullet text is concatenated onto the previous paragraph, and
- the line *after* the list (the `PR:` line) is glued onto the last bullet.

So every ticket block needs a blank line **between the bold ticket header and the first bullet**, and another **between the last bullet and the `PR:` line**. This is non-negotiable — it is a verified, repeated failure.

```
**Ticket: <link> - Title** :white_check_mark:
                                  ← blank line required
- first bullet
- last bullet
                                  ← blank line required
PR: <url>
```

## 3. Brackets adjacent to link syntax

In the mrkdwn `<url|label>` form, brackets placed immediately outside the link can break the enclosing bold span. Put them **inside** the label:

- Good: `**Ticket: <url|[KEY]> - Title**`
- Bad: `**Ticket: [<url|KEY>] - Title**`

## Verify before sending

Re-read the composed message and check, in order:

1. Every intended bold span uses the right number of asterisks for this renderer.
2. Every bullet list has a blank line above the first item and below the last.
3. Every ticket block is separated from the next by a blank line.
4. Brackets sit inside link labels.
5. No footer, no attribution.

## Rules

1. Confirm the renderer's flavour before composing; never assume from another platform.
2. Blank line before the first bullet and after the last, every time.
3. Brackets inside link labels.
4. Re-read the whole message against this list before sending — a posted message can't be quietly fixed.
