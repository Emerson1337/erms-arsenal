---
title: Two kinds of release notes — technical and public
impact: HIGH
tags: [release-notes, changelog, communication]
---

# Two kinds of release notes

A release produces **two different documents for two different readers**. Writing one and hoping it serves both is the usual failure: engineers get marketing fluff, or customers get `refactor(deps): bump transitive lockfile`.

Both derive from the same immutable range: `<previous-tag>..<this-tag>`, or `LAST_FINAL..$SHA` at tag-creation time when the tag doesn't exist yet. **Never derive notes from a live branch ref** — by the time you write them the source branch may have moved past the commit you tagged, and a live range over-claims work that didn't ship in this build.

```bash
git -C <path> log --pretty='%s%n%b%x00' <previous-tag>..<this-tag>
gh pr list --repo <slug> --state merged --search 'merged:<date-range>' --json number,title,body
```

## 1. Technical notes — the GitHub Release body

Audience: engineers, reviewers, whoever debugs this version at 2am. Complete beats readable.

```markdown
## What's in <tag>

### Features
- <commit subject, prefix stripped> (<ticket-link>)

### Fixes
- <…>

### Internal
- <refactors, dependency bumps, CI changes>

### Migrations
- `<name>` (<schema>) — <one line on what it changes>

**Compare:** https://github.com/<slug>/compare/<previous-tag>...<this-tag>
```

- Group by commit-subject type (`feat`/`fix`/`chore`/`refactor`…) when the project uses conventional commits; otherwise group by what the change *is*, judged from the subject.
- Link ticket keys through `tracker.urlTemplate`. Keys come from `tracker.commitPattern` — see `rules/integrations.md`.
- Dedup: a squash-merged PR appears once. Drop merge commits (`Merge pull request …`, `Merge branch …`) entirely.
- Keep the ticket keys, keep the file/module names where they help. This document is allowed to be dry.
- A repo with no changes in a lockstep release gets exactly: `- No changes since <previous-tag>.`

## 2. Public release notes — shareable as-is

Audience: customers, an app-store listing, a changelog page, a support team. This is the artifact the user asked for and the one that's usually skipped. Generated whenever `releaseNotes.public` is true; written to `releaseNotes.file` when set, and always handed back as a copy-pasteable block.

```markdown
## <Version> — <Month D, YYYY>

**New**
- <What the user can now do, in their words.>

**Improved**
- <What got faster, clearer, or less annoying — and how it shows up.>

**Fixed**
- <What was broken, described as the user experienced it.>
```

Rules that make it publishable:

- **Write from the user's side of the screen.** Not "added a debounce to the search input" → "Search now updates as you type without lagging."
- **Drop every internal reference**: ticket keys, PR numbers, commit SHAs, branch names, repo names, service names, table and column names, env vars, library names, and anyone's username. If a line can't survive losing those, it's an internal change — put it under Internal in the technical notes and leave it out here.
- **Omit, don't pad.** Dependency bumps, CI changes, refactors with no visible effect, and reverts of unreleased work do not appear. A release whose public notes read "Fixed — Stability and performance improvements." is an honest release with no user-visible changes; say that rather than inventing three bullets.
- **One line per change, no nesting.** Merge several commits that served one outcome into one bullet.
- **Say what changed, not that you changed it.** "Invoices now export to Excel" beats "We've added the ability to export invoices."
- **No superlatives, no roadmap, no apologies.** Not "we're thrilled", not "coming soon", not "sorry for the inconvenience".
- **Skip empty sections** entirely rather than writing "None".
- **Respect `releaseNotes.maxChars`** when set (app-store listings cap out — commonly 4000). Trim by dropping the least user-visible bullets from the bottom up, never by truncating mid-sentence. Say how many items you dropped.
- Prereleases usually don't get public notes — they're not public. Generate them only if the user asks or the tier's config says so.

## Deriving one from the other

Work in this order, because it's the order that keeps the public notes honest:

1. Build the technical list from the commit range.
2. Mark each entry user-visible or internal. When you can't tell from the subject, read the PR body — and if it's still ambiguous, treat it as internal.
3. Rewrite only the user-visible entries in user language, merging duplicates by outcome.
4. Re-read the result as a customer with no context. Any line that needs internal knowledge to parse gets rewritten or dropped.

## Rules

1. Derive from the immutable tag range, never from a live branch.
2. Two documents, two audiences — produce both, and never publish the technical one as the public one.
3. Public notes carry zero internal identifiers: no ticket keys, PR numbers, SHAs, repo, service, table, or user names.
4. Omitting a change is always better than padding or inventing one.
5. Honour `maxChars` by dropping whole bullets and reporting what was dropped.
