---
title: Use Reducer + Context for Shared Client State
impact: HIGH
tags: [state-management, context, reducer]
---

# Use Reducer + Context for Shared Client State

Model non-trivial shared client state with `useReducer` and context providers.

## Why

- Keeps transitions explicit and testable
- Reduces fragmented state spread across distant components
- Encourages predictable updates under concurrent UI changes

## Pattern

```ts
interface AppState {
  hasHydrated: boolean;
  isSyncing: boolean;
}

type AppAction = { type: "hydrated" } | { type: "set-syncing"; value: boolean };

function appReducer(state: AppState, action: AppAction): AppState {
  if (action.type === "hydrated") return { ...state, hasHydrated: true };
  if (action.type === "set-syncing") return { ...state, isSyncing: action.value };
  return state;
}
```

## Rules

1. Use reducer actions for shared state transitions.
2. Keep local-only ephemeral UI in component state.
3. Split contexts by domain to prevent broad re-renders.
