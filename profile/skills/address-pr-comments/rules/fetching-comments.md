---
title: Fetch every comment surface on a PR
impact: HIGH
tags: [github, gh-cli, review-comments]
---

# Fetch every comment surface on a PR

A PR carries feedback in three separate places. Miss one and you leave comments unaddressed. Pull all three, then filter out resolved threads and your own prior replies.

Prefer GitHub MCP tools (`mcp__github__*`) when the server is loaded — see the global `CLAUDE.md` preference. The `gh` commands below are the reliable fallback.

## Parse the URL first

```
https://github.com/<owner>/<repo>/pull/<number>
   →   OWNER=<owner>  REPO=<repo>  PR=<number>
```

Confirm you're on the PR's branch so evaluation and edits hit the real code:

```bash
gh pr checkout "$PR"          # or: git fetch && git checkout <branch>
```

## 1. Inline review threads (the main event)

Line-anchored, and the only ones you resolve. GraphQL gives thread node ids (needed to resolve) plus resolution state in one shot:

```bash
gh api graphql -f query='
query($owner:String!,$repo:String!,$pr:Int!){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$pr){
      reviewThreads(first:100){
        nodes{
          id
          isResolved
          isOutdated
          path
          line
          comments(first:50){
            nodes{ databaseId author{login} body path line diffHunk url }
          }
        }
      }
    }
  }
}' -F owner="$OWNER" -F repo="$REPO" -F pr="$PR"
```

- Skip nodes where `isResolved` is `true`.
- The thread's `id` is what `resolveReviewThread` takes.
- The **first** comment's `databaseId` is what you reply to.
- `isOutdated: true` means the code moved since the comment — read the current code, the point may already be moot.

## 2. Review summary bodies

The overall "request changes / approve / comment" text left at submission:

```bash
gh pr view "$PR" --repo "$OWNER/$REPO" --json reviews \
  --jq '.reviews[] | select(.body != "") | {author:.author.login, state:.state, body:.body}'
```

## 3. Issue-level PR comments

Plain conversation-tab comments, not line-anchored:

```bash
gh api "repos/$OWNER/$REPO/issues/$PR/comments" \
  --jq '.[] | {id:.id, author:.user.login, body:.body}'
```

## Rules

1. Always pull all three surfaces — threads, review bodies, issue comments.
2. Filter out resolved threads and comments authored by the PR author or yourself.
3. Keep each thread's node `id` **and** its first comment's `databaseId` — you need both later.
4. Read the current code at each `path:line` before judging; outdated threads often self-resolve.
