---
description: Every plan-mode plan opens with a short summary for the product owner
---

# Every plan opens with a summary for the product owner

When you write a plan in **plan mode** — the file the CLI requires you to write
before calling `ExitPlanMode` — the plan must begin with a short, non-technical
summary aimed at a **product owner**, followed by the technical plan.

This is not decoration. A plan is read by people deciding *whether to approve
the work*, not only by whoever implements it. The first screen has to answer
their question, not yours.

## The shape

Start the file with these two sections, in this order, before anything else:

```markdown
# <the plan's title>

## Summary

<one-line thesis>

<optional extra context — a sentence or two, not a restatement of the thesis>

- <bullet>
- <bullet>

## Plan

<the technical plan, exactly as you would have written it>
```

Use those exact headings — `## Summary` then `## Plan` — so plans read
consistently. Do **not** add subheadings under Summary (`### Thesis`,
`### Context`, …): anything that extracts the summary (a PR draft, a viewer)
takes everything until the next heading, so a subheading would cut it short.

Everything you would normally put in a plan goes under `## Plan`, unchanged and
at full technical depth. The summary is **added**, never a substitute: do not
thin out the technical plan because you wrote a summary above it.

## What belongs in the summary

Three beats, in this order. Skip a beat only when it would just repeat the one
above it.

1. **Thesis (required, one line).** The whole plan in one sentence — what
   someone using the product will be able to do, or will stop being bothered
   by. If nothing user-visible changes, say so plainly ("no visible change;
   this is groundwork for X").
2. **Context (optional).** Why it's worth doing, and which part of the product
   it touches, in product language ("the sign-in page", "invoice export"), not
   paths. One or two sentences. Omit if the thesis already says it.
3. **Bullets.** The scannable list the owner actually uses: what they'll see,
   anything they have to decide or accept (a tradeoff, a risk, a thing that
   will look different afterwards), and work explicitly left out of scope.
   Don't pad. A one-line copy tweak can skip the bullets.

## What must NOT appear in the summary

- File paths, function, class, component, table, or column names
- Line numbers, code snippets, type signatures, config keys
- Framework, library, or tool names, unless the owner would recognise it as a
  product they pay for
- Implementation vocabulary: "refactor", "hook", "endpoint", "migration",
  "state", "props", "cache", "worktree"

Write it as you would say it out loud to someone who knows the product well and
has never seen the codebase. A good test: if a sentence would make no sense to
someone who has never opened an editor, rewrite it.

## Length and proportion

The thesis is one line. Context is at most two short sentences. Bullets are
few — usually two to five, never a dump of the Plan section.

Scale to the size of the work: a large feature earns context and bullets; a
typo fix is a thesis and nothing else. Padding a small change out is worse than
keeping it short.

## Applies to

Every plan-mode plan, including small ones. It does **not** apply to ordinary
answers, research write-ups, commit messages, or PR bodies — only to the plan
file that `ExitPlanMode` presents for approval.
