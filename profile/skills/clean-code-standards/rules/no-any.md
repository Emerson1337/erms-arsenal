---
title: Never Use any
impact: HIGH
impactDescription: type safety and runtime error prevention
tags: typescript, types, safety, conventions
---

## Never Use any

`any` is banned. Not in app code, not in tests, not "temporarily". This includes implicit `any`
from untyped parameters and from `catch` clauses.

### Why

1. **It turns type checking off** — every property access, call, and assignment on an `any` is
   unchecked, so the compiler stops helping at that point
2. **It spreads** — an `any` flows into everything it touches, so one of them silently unchecks
   whole call chains
3. **It hides the real question** — reaching for `any` means the shape isn't known yet, and the fix
   is to find out, not to opt out
4. **Refactors stop being safe** — rename a field and every `any` path keeps compiling and starts
   failing at runtime instead

### The Escalation Ladder

Work down this list. Stop at the first one that fits — you never reach `any`.

1. **A real type** — the shape is known, so write it
2. **A generic** — the shape varies but the caller knows it
3. **`unknown` + a type guard** — the shape is not known at compile time
4. **Zod at the boundary** — data crossing into the program (network, storage, `process.env`, files)

See `@rules/no-as-type-casts.md` for the type guard and Zod patterns.

### Bad: Untyped Data

```typescript
// Bad: response shape unchecked from here on
async function getUser(id: string): Promise<any> {
  let response = await fetch(`/api/users/${id}`);
  return response.json();
}

// Bad: nothing catches the typo
let user = await getUser("1");
console.log(user.nmae);
```

### Good: Validate at the Boundary

```typescript
const UserSchema = z.object({ id: z.string(), name: z.string() });
type User = z.infer<typeof UserSchema>;

async function getUser(id: string): Promise<User> {
  let response = await fetch(`/api/users/${id}`);
  return UserSchema.parse(await response.json());
}
```

### Bad: Untyped catch

```typescript
// Bad: e is any, so e.message compiles even when e is a string
try {
  await save(order);
} catch (e: any) {
  logger.error(e.message);
}
```

### Good: Narrow the Error

```typescript
try {
  await save(order);
} catch (error: unknown) {
  logger.error(error instanceof Error ? error.message : String(error));
}
```

TypeScript already types `catch` bindings as `unknown` under `useUnknownInCatchVariables`
(on with `strict`), so the annotation is only there when the default is off.

### Bad: any as a Wildcard Shape

```typescript
// Bad: no checking on anything read out of it
function log(context: Record<string, any>) { ... }

// Bad: the arguments and return are both unchecked
function withRetry(fn: (...args: any[]) => any) { ... }
```

### Good: unknown and Generics

```typescript
// Good: unknown forces the reader to narrow before use
function log(context: Record<string, unknown>) { ... }

// Good: generics carry the caller's real types through
function withRetry<TArgs extends unknown[], TResult>(
  fn: (...args: TArgs) => Promise<TResult>,
): (...args: TArgs) => Promise<TResult> { ... }
```

### The One Exception

Declaring types for a dependency that ships none can require `any` to match its actual signature.
Isolate it in a declaration shim (`types/<package>.d.ts`) with a one-line reason, and keep it out
of application code. Every consumer still sees a real type.

```typescript
// types/legacy-charts.d.ts
// Upstream ships no types; the callback really is untyped in its source.
declare module "legacy-charts" {
  export function render(target: HTMLElement, onPoint: (point: any) => void): void;
}
```

`unknown` is the better choice even here whenever the shim compiles with it.

### Enforcement

`@typescript-eslint/no-explicit-any` and `strict: true` in `tsconfig.json` catch these. Suppressing
either one is separately banned — see `@rules/no-lint-suppression.md`.

### Summary

| Instead of                     | Use                                        |
| ------------------------------ | ------------------------------------------ |
| `Promise<any>` from an API     | Zod schema + `z.infer`                     |
| `catch (e: any)`               | `catch (error: unknown)` + `instanceof`    |
| `Record<string, any>`          | `Record<string, unknown>`                  |
| `(...args: any[]) => any`      | Generic type parameters                    |
| `let value: any` while drafting | `unknown`, then narrow before first use   |
