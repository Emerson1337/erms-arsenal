---
title: No Type Assertions (as Type)
impact: HIGH
impactDescription: type safety and runtime error prevention
tags: typescript, types, safety, conventions
---

## No Type Assertions (as Type)

Avoid `as Type` casts. Use type guards, validation, or proper typing instead.

### Why

1. **Bypasses type checking** - Tells TypeScript to trust you, even when wrong
2. **Hides bugs** - Runtime errors instead of compile-time errors
3. **False confidence** - Code looks type-safe but isn't
4. **Maintenance risk** - Types change, casts don't update

### Bad: Type Assertions

```typescript
// Bad: asserting unknown data
let user = response.data as User;

// Bad: asserting array type
let items = data as Item[];

// Bad: asserting element type
let button = document.querySelector(".btn") as HTMLButtonElement;

// Bad: asserting form data
let file = formData.get("file") as File;

// Bad: forcing type compatibility
let config = rawConfig as Config;
```

### Good: Proper Alternatives

#### Use Type Guards

```typescript
function isUser(data: unknown): data is User {
  return (
    typeof data === "object" && data !== null && "id" in data && "name" in data
  );
}

// Good: validated at runtime
if (isUser(response.data)) {
  let user = response.data; // Typed as User
}
```

#### Use Zod Validation

```typescript
import { z } from "zod";

const UserSchema = z.object({
  id: z.string(),
  name: z.string(),
  email: z.string().email(),
});

// Good: validated and typed
let user = UserSchema.parse(response.data);
```

#### Use instanceof for Runtime Classes

```typescript
// Bad
let button = document.querySelector(".btn") as HTMLButtonElement;

// Good: check for null and instanceof
let element = document.querySelector(".btn");
if (element instanceof HTMLButtonElement) {
  element.disabled = true;
}
```

The same applies to anything the platform hands back as a union — `FormData.get()` returns
`FormDataEntryValue | null`, so check it rather than assert it:

```typescript
// Good: the check the cast was skipping
let file = formData.get("file");
if (!(file instanceof File)) {
  return new Response("No file provided", { status: 400 });
}
```

#### Use Generic Functions

```typescript
// Bad
function getData<T>(key: string): T {
  return localStorage.getItem(key) as T;
}

// Good: return unknown, let caller validate
function getData(key: string): unknown {
  let value = localStorage.getItem(key);
  return value ? JSON.parse(value) : null;
}

// Caller validates
let rawData = getData("user");
let user = UserSchema.parse(rawData);
```

#### Annotate the Target Instead of Casting the Value

A cast used to fix an inferred type is usually an annotation in the wrong place.

```typescript
// Bad: casting the initial value
let groups = users.reduce(
  (accumulator, user) => { ... },
  { admins: [], testers: [] } as Record<UserGroup, User[]>,
);

// Good: tell reduce what it's building
let groups = users.reduce<Record<UserGroup, User[]>>(
  (accumulator, user) => { ... },
  { admins: [], testers: [] },
);
```

#### Fix the Types

```typescript
// Bad: cast because types don't match
let result = processData(input) as ExpectedOutput;

// Good: fix the function's return type
function processData(input: Input): ExpectedOutput {
  // ...
}
```

### Not Assertions — These Are Fine

#### `as const`

A literal-narrowing annotation, not a claim about an unchecked value. It makes types *more* precise
and is the prescribed alternative to `enum` (see the `frontend-react-native-expo-best-practices`
skill).

```typescript
// Good
const ORDER_STATUSES = ["draft", "open", "closed"] as const;
type OrderStatus = (typeof ORDER_STATUSES)[number];
```

#### `satisfies`

When the goal was shape-checking rather than shape-claiming, `satisfies` is the right operator: it
verifies the value against the type and keeps the narrow inferred type.

```typescript
// Bad: widens, and hides a missing key
const ROUTES = { home: "/", settings: "/settings" } as Record<RouteName, string>;

// Good: checks every key exists, keeps the literal types
const ROUTES = { home: "/", settings: "/settings" } satisfies Record<RouteName, string>;
```

### Acceptable Uses

#### Branded Types in Zod Transforms

```typescript
// Acceptable: branding IDs in deserializers
const Schema = z.object({
  id: z.string().transform((id) => id as UserId),
  name: z.string(),
});
```

#### Test Mocks (sparingly)

```typescript
// Acceptable in tests: partial mocks
let mockUser = { id: "1", name: "Test" } as User;
```

### Summary

| Instead of                     | Use                                  |
| ------------------------------ | ------------------------------------ |
| `data as User`                 | Zod schema validation                |
| `element as HTMLButtonElement` | `instanceof` check                   |
| `formData.get("f") as File`    | `instanceof` check                   |
| `value as SomeType`            | Type guard (`value is SomeType`)     |
| `response as T`                | Generic with validation              |
| `initialValue as Shape`        | Annotate the generic: `reduce<Shape>` |
| `object as Record<K, V>`       | `satisfies Record<K, V>`             |
