---
title: Prefer Interfaces and Object Maps
impact: HIGH
tags: [typescript, conventions, maintainability]
---

# Prefer Interfaces and Object Maps

Use interfaces for object contracts and object maps for finite values instead of enums.

## Why

- Interfaces compose cleanly across module boundaries
- Object maps avoid enum runtime output and reduce indirection
- Works well with strict TypeScript settings

## Incorrect

```ts
enum ScreenState {
  Idle,
  Loading,
  Error,
}
```

## Correct

```ts
export const ScreenState = {
  idle: "idle",
  loading: "loading",
  error: "error",
} as const;

export interface ProfileState {
  isLoading: boolean;
  hasError: boolean;
  screenState: (typeof ScreenState)[keyof typeof ScreenState];
}
```

## Rules

1. Use interfaces for component props and data models.
2. Prefer `as const` maps over enums for value sets.
3. Keep `strict` TypeScript enabled.
