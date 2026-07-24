---
title: Refresh Server State on Foreground
impact: HIGH
tags: [appstate, data, react-query]
---

# Refresh Server State on Foreground

Invalidate stale server-backed queries when the app returns to active state.

## Why

- Mobile apps frequently resume after long background periods
- Prevents showing stale account balances, order status, or messages
- Keeps data freshness aligned with user expectations

## Pattern

```ts
import { AppState } from "react-native";

useEffect(() => {
  const sub = AppState.addEventListener("change", (state) => {
    if (state === "active") {
      queryClient.invalidateQueries({ queryKey: ["viewer"] });
      queryClient.invalidateQueries({ queryKey: ["orders"] });
    }
  });

  return () => sub.remove();
}, [queryClient]);
```

## Rules

1. Invalidate critical user data when transitioning to `active`.
2. Avoid blanket invalidation of every query for large apps.
3. Combine with sensible stale times to reduce request spikes.
