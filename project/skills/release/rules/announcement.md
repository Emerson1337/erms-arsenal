---
title: Compose the release announcement
impact: MEDIUM
tags: [chat, slack, announcement, formatting]
---

# Compose the release announcement

The internal "it shipped" message, for the team channel. Distinct from both the GitHub Release body (too long) and the public notes (wrong audience — the team wants links and digests).

Post it only when `chat.post` is `true`. Otherwise hand the user one copy-pasteable block and name the destination from `chat.channel`. See `rules/integrations.md` for how each provider formats and sends.

## Shape

One header line, then **one block per participating repo** — including repos with no changes, when `lockstep` is on:

```
<emoji> <TIER label> release `<VERSION>` — deployed to <ENV>.

<repo>
<one-line summary of the work, items joined by · >
<migrations line, when the repo has a database>
<artifact digest or published version>
• Release notes: <release-url>
• Deploy run: <run-url>
• Compare: <compare-url>
```

Filling it in:

- **Header** — the tier's `label` (falling back to its `name`), the version, and the tier's `env`. State the outcome plainly: how many repos are green, or nothing if there's only one.
- **Summary line** — terse items joined by ` · `, computed **from the immutable tag range** (`git log <previous-tag>..<this-tag>`), not from a live branch: by hand-off time the source branch may have advanced past what you tagged, and a live range over-claims commits that never shipped. Strip `feat:`/`fix:` prefixes. Append ticket keys in parentheses when `tracker.prefix` is set. Non-ticket infra work goes at the end.
- **Migrations line** — take it from the step-4 deploy log's applied summary (`migrations.appliedLogPattern`), never from the step-2 branch diff, which can undercount. List each applied migration with its schema. No database, or nothing applied → say so in one short clause.
- **Artifact line** — the digest, version, or published function/package identity captured in step 4 (`artifact.digestLogPattern`). A short digest prefix is enough; the point is that it's traceable.
- **Links** — Release notes, deploy run, and `https://github.com/<slug>/compare/<previous-tag>...<this-tag>`.
- **No-change repo** — replace the summary line with `No changes since <previous-tag> — tagged to keep the shared version aligned.`, and include **only** the Release notes link: nothing deployed, so there's no run and no compare.

## The separator invariant

> **A blank line between every repo block. Non-negotiable.** Every repo header except the first MUST have a literal empty line directly above it.

Chat renderers do not insert spacing on their own. Without that blank line, one repo's last link line runs straight into the next repo's name and the whole message reads as a single undifferentiated blob. This is a recurring, real defect — it is why this rule exists as its own section.

The blank lines are part of the message body, so they must survive into the block you hand the user, not merely appear in this template.

**Count them before handing off:** for N participating repos there are exactly **N−1** blank lines separating blocks, plus one after the header line.

## Final check before hand-off

Re-read the composed message top to bottom and confirm:

1. A blank line after the header.
2. A blank line immediately above every repo header except the first.
3. Every link resolves to the right repo — a copy-pasted block with repo A's run URL under repo B is worse than no announcement.
4. No internal jargon that the channel's audience won't parse, and no AI attribution anywhere.

Only hand it over once every block is visually separated. If a repo header is glued to the previous block's last line, insert the blank line and re-check from the top.

## Rules

1. Compute the summary from the tag range, and the migration list from the deploy log.
2. One block per participating repo, no-change repos included under lockstep.
3. N−1 separating blank lines for N repos, verified by counting, plus one after the header.
4. Post only when `chat.post` is true; otherwise hand over a single copy-pasteable block and name the destination.
