---
title: Reply to and resolve review threads
impact: HIGH
tags: [github, gh-cli, graphql, resolve-thread]
---

# Reply to and resolve review threads

Only after GATE 2 (final summary approved). **Reply first, then resolve** — a resolved thread with no reply reads as dismissive.

Prefer GitHub MCP tools (`mcp__github__*`) when loaded; the `gh` commands here are the fallback.

## Reply to an inline review thread

Post as a reply to the thread's **first comment** (`databaseId` from the fetch query):

```bash
gh api "repos/$OWNER/$REPO/pulls/$PR/comments/$COMMENT_ID/replies" \
  -f body='Done — extracted to a shared helper and reused here.'
```

One or two sentences (see SKILL.md "Style for replies").

## Resolve the thread

Use the thread **node `id`**, not the comment id:

```bash
gh api graphql -f query='
mutation($id:ID!){
  resolveReviewThread(input:{threadId:$id}){ thread { isResolved } }
}' -F id="$THREAD_ID"
```

Confirm the response shows `isResolved: true`.

## Reply to a review summary or issue-level comment

No thread to resolve — post a top-level PR comment:

```bash
gh pr comment "$PR" --repo "$OWNER/$REPO" \
  --body 'Addressed the two inline points; the perf note is out of scope here — filed as a follow-up.'
```

## Committing the code changes

Commit only the approved edits, following the repo's own convention — read it from `git log --oneline -20` rather than assuming a format.

```bash
git add <approved files>
git commit -m '<message in the repo's convention>'
```

- **No** `Co-Authored-By` or AI attribution lines.
- **Do not push** unless explicitly asked.
- If a sandbox blocks a push that was requested, use the `gh`-token HTTPS method documented in the global `CLAUDE.md`.

## Rules

1. Reply before resolving; never resolve silently.
2. Inline threads: reply target = first comment's `databaseId`, resolve target = thread node `id`.
3. Review-body and issue comments get a top-level comment, no resolve step.
4. Commit in the repo's convention, no AI attribution, no push unless asked.
