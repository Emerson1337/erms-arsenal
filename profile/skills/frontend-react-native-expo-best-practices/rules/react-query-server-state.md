---
title: Use React Query for Server State
impact: HIGH
tags: [react-query, networking, caching]
---

# Use React Query for Server State

Use React Query for server-backed data, retries, background refresh, and cache invalidation.

## Why

- Prevents redundant API calls and request waterfalls
- Gives stale-while-revalidate behavior with minimal boilerplate
- Improves offline/poor-network user experience

## Pattern

```ts
const profileQuery = useQuery({
  queryKey: ["profile", userId],
  queryFn: () => fetchProfile(userId),
  staleTime: 30_000,
});
```

## Rules

1. Keep server data in React Query, not ad-hoc global stores.
2. Use stable query keys tied to real parameters.
3. Invalidate narrowly after successful mutations.
