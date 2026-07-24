---
title: Run the handoff steps in parallel
impact: MEDIUM
tags: [performance, mcp, github]
---

# Run the handoff steps in parallel

The three steps — GitHub assign, ticket comment, ticket status move — have no data dependencies. Emit all three tool calls in a **single** turn so they run concurrently.

## Why

- **Latency** — each call hits a different service. Serializing adds seconds of wall time for nothing.
- **Atomic feel** — from the user's side the ritual either happened or it didn't. Interleaved progress chatter between three serial calls is noise.
- **Failure isolation** — if one step fails (a rejected status string, say), the others have already succeeded, so recovery is targeted instead of "do steps 2 and 3 again".

## Pattern

```text
# Good — one turn, three tool uses
1. assign PR to <assignee>
2. comment the PR URL on the ticket
3. move the ticket to <reviewStatus>

# Bad — three sequential turns, each waiting on the last
```

## Rules

1. All steps in one assistant message.
2. Don't gate any step on another's success.
3. If one fails, fix only that one — never redo the others.
