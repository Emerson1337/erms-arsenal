---
title: Every PR with a visible change carries highlighted screenshots
impact: HIGH
tags: [github, review, screenshots]
---

# Every PR with a visible change carries highlighted screenshots

A reviewer should see what changed without running the branch. Any PR that changes something a user can see gets a `## Screenshots` section above `## Test plan`, and every screenshot outlines the changed area so it stands out from the rest of the page.

This applies to draft PRs too: the screenshots are part of the PR, not a review request.

## What to capture

- One screenshot per visible change, in the order a user meets them.
- The whole window for context, with the changed area outlined. Crop only when the change is tiny and the surrounding page adds nothing.
- Real-looking content (a demo record with plausible data), never an empty or broken page.
- Each image gets a one-line bold caption saying what it shows.

## How to highlight

- Outline the changed element with a 3 px red (`#ff2d55`) rounded ring, plus a short red tag naming the change ("New: export button", "+ Panel", "Label after ~0.5 s hover").
- Place the tag so it never covers other UI text: above by default, to the right or left when the element sits at the top edge or inside a menu.
- Draw the ring in the page itself before capture (an injected fixed-position overlay) rather than editing the image afterwards.

## How to take them

1. Run the branch locally with the repo's own start command (from its README or `CLAUDE.md`), and load data that makes the changed screen look real.
2. Drive it with `playwright-core` and an installed Chrome or Chromium, viewport 1440×860, `deviceScaleFactor: 2`.
3. Inject the highlight ring, screenshot, remove the ring, move to the next state.
4. Look at every image before posting. Fix overlaps, encoding glitches (`Â·` means a missing `charset=utf-8`), or a tag covering text, and retake.
5. Watch the browser console while capturing. A runtime error found here is a bug in the PR: fix it on the PR branch first.

## Where they live

- Push the images to an orphan branch named `pr-<num>-screenshots`, under `pr-<num>/NN-short-name.png`.
- Reference them in the PR body as `https://github.com/<owner>/<repo>/blob/pr-<num>-screenshots/pr-<num>/<file>.png?raw=true`.
- On a private repo an anonymous `curl` returns 404. Confirm the files with `gh api repos/<owner>/<repo>/contents/pr-<num>?ref=pr-<num>-screenshots` instead.

## When to skip

- The PR has no visible change (server-only, tests, docs, config). Say so in one line in the PR body ("No UI change.") instead of adding the section.
- The user says not to.
