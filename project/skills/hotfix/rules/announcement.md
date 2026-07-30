---
title: Compose the hotfix announcement
impact: MEDIUM
tags: [hotfix, chat, slack, announcement, formatting]
---

# Compose the hotfix announcement

The internal "this is patched" message. A release announcement says what shipped; a **hotfix announcement says what was broken, where it's fixed now, and where it isn't yet** — because a hotfix is usually announced while at least one environment is still in flight.

Post it only when `chat.post` is `true`. Otherwise hand the user one copy-pasteable block and name the destination from `chat.channel`. See `../../release/rules/integrations.md` for how each provider formats and sends.

## Shape

One header, then **one block per participating environment**, then the trunk line:

```
<emoji> Hotfix `<VERSION>` — <what was broken, in one clause>

<ENV label> (<branch>) — <status>
<repo> · <artifact digest>
<migrations line, when any applied>
• PR: <pr-url>
• Deploy run: <run-url>
• Release notes: <release-url>

<next ENV label> (<branch>) — <status>
...

Trunk (<trunk-branch>): <merged | PR open — the fix is not permanent until this lands>
```

Filling it in:

- **Header** — the version and the **symptom**, not the patch. "Hotfix `v2.4.1` — login failed on expired sessions" tells the channel why they care; "Hotfix `v2.4.1` — updated session guard" doesn't. Include the ticket key when `tracker.prefix` is set.
- **Environment block** — the tier's `label` (falling back to `name`), its branch, and its real status: `deployed`, `merged, deploy running`, or `PR open`. Never write `deployed` for an environment whose run you didn't watch go green.
- **Migrations line** — from the deploy log's applied summary (`migrations.appliedLogPattern`), never from a branch diff. Nothing applied → omit the line entirely rather than writing "no migrations".
- **Artifact line** — the digest or published version captured during verification. A short digest prefix is enough; the point is that it's traceable.
- **Links** — PR, deploy run, and Release notes. An environment with nothing merged yet has only its PR link — don't fabricate the others.
- **Trunk line** — always present, always last, and explicit when it's still open. This is the line that saves the team from shipping the same bug again next release.

## Say what isn't done

A hotfix announcement sent mid-fan-out is normal and useful — the team needs to know production is patched. It just has to be honest about the rest:

```
🚑 Hotfix `v2.4.1` — login failed on expired sessions (<KEY>-<n>)

Production (main) — deployed
api · sha256:9f2c1ab
• PR: <url>
• Deploy run: <url>
• Release notes: <url>

Staging (staging) — PR open
• PR: <url>

Trunk (develop): PR open — the fix is not permanent until this lands
```

Never round an in-flight environment up to done, and never quietly drop an environment from the list because it's blocked. A blocked environment with its conflict named is information; a missing one reads as fixed.

## The separator invariant

> **A blank line between every block. Non-negotiable.** Every environment header except the first MUST have a literal empty line directly above it, and the trunk line MUST have one above it too.

Chat renderers do not insert spacing on their own. Without that blank line, one environment's last link runs straight into the next environment's name and the whole message reads as a single undifferentiated blob. This is the same recurring defect the release announcement rule calls out, and it recurs here for the same reason.

The blank lines are part of the message body, so they must survive into the block you hand the user, not merely appear in this template.

**Count them before handing off:** for N environments there are exactly **N−1** blank lines separating the environment blocks, plus one after the header and one before the trunk line.

## Final check before hand-off

Re-read the composed message top to bottom and confirm:

1. A blank line after the header, above every environment header except the first, and above the trunk line.
2. Every status matches what you actually verified — no environment marked deployed on an unwatched run.
3. Every link resolves to the right environment. Production's run URL under staging's block is worse than no announcement.
4. The trunk line is present and states its real state.
5. The header names the symptom, and there's no internal jargon the channel won't parse and no AI attribution anywhere.

Only hand it over once every block is visually separated. If an environment header is glued to the previous block's last line, insert the blank line and re-check from the top.

## Rules

1. Lead with the symptom and the version, not the mechanics of the patch.
2. One block per participating environment, with its true status — never round in-flight up to deployed.
3. The trunk line is always present and always last.
4. N−1 separating blank lines for N environments, verified by counting, plus one after the header and one before trunk.
5. Migration list comes from the deploy log; omit the line when nothing applied.
6. Post only when `chat.post` is true; otherwise hand over a single copy-pasteable block and name the destination.
