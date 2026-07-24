---
title: Validate Boundaries with Zod
impact: CRITICAL
tags: [validation, zod, error-handling]
---

# Validate Boundaries with Zod

Validate network payloads, deep-link params, and persisted payloads at boundaries before using them.

## Why

- Prevents malformed data from causing runtime crashes
- Converts implicit assumptions into explicit contracts
- Enables safe early-return error handling

## Pattern

```ts
const UserSchema = z.object({
  id: z.string(),
  email: z.string().email(),
});

function parseUser(payload: unknown) {
  const result = UserSchema.safeParse(payload);
  if (!result.success) return null;
  return result.data;
}
```

## Rules

1. Validate unknown data at the entry point.
2. Use early returns for invalid states.
3. Keep schemas close to the boundary they protect.
