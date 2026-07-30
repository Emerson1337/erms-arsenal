---
name: clean-code-standards
description: Non-negotiable code quality standards — never `any`, never `as` assertions (write type guards), never suppress a linter, never chain ternaries, comments as a last resort, and object calisthenics at medium effort. Use when writing, reviewing, or refactoring any TypeScript or JavaScript code.
---

# Clean Code Standards

The standards that apply to every line of TypeScript and JavaScript, regardless of framework.
6 rules. Four of them are hard bans — the code doesn't ship with `any`, an `as` assertion, a
suppressed lint rule, or a chained ternary in it.

The goal is clean, reusable code: types that are actually checked, units small enough to reuse, and
intent visible without a comment explaining it.

## When to Apply

Reference these whenever you:

- Write or refactor any TypeScript or JavaScript
- Review a diff or a pull request
- Handle data crossing a boundary — a fetch response, form data, storage, `process.env`
- Hit a lint or type error and are deciding what to do about it
- Find yourself about to write a comment

Framework-specific guidance lives in the `frontend-*-best-practices` skills. These rules sit
underneath all of them and win on conflict.

## Rules Summary

### no-any (HIGH) — @rules/no-any.md

`any` is banned. A real type → a generic → `unknown` plus a type guard → Zod at the boundary.

```typescript
// Bad: type checking is off from here on
async function getUser(id: string): Promise<any> { ... }
try { ... } catch (e: any) { logger.error(e.message); }

// Good: validated at the boundary, narrowed in the handler
async function getUser(id: string): Promise<User> {
  return UserSchema.parse(await response.json());
}
try { ... } catch (error: unknown) {
  logger.error(error instanceof Error ? error.message : String(error));
}
```

### no-as-type-casts (HIGH) — @rules/no-as-type-casts.md

Avoid `as Type` casts. Write a type guard or validate with Zod. `as const` and `satisfies` are fine.

```typescript
// Bad: type assertion
let user = response.data as User;

// Good: Zod validation
let user = UserSchema.parse(response.data);

// Good: type guard
if (isUser(response.data)) {
  let user = response.data;
}
```

### no-lint-suppression (HIGH) — @rules/no-lint-suppression.md

Never silence a linter or the type checker. Fix the code, or change the shared config.

```typescript
// Bad: the missing dependency is a real bug
// eslint-disable-next-line react-hooks/exhaustive-deps
useEffect(() => { sync(orderId); }, []);

// Good: declare what the effect uses
useEffect(() => { sync(orderId); }, [orderId]);
```

Never add a suppression to make a check pass — report the blocker instead.

### ternary-one-level-max (MEDIUM) — @rules/ternary-one-level-max.md

One level is the ceiling. Chained and nested ternaries are banned.

```typescript
// Bad: chained
let label = status === "open" ? "Open" : status === "draft" ? "Draft" : "Unknown";

// Good: lookup map
const STATUS_LABELS: Record<OrderStatus, string> = { open: "Open", draft: "Draft" };
let label = STATUS_LABELS[status] ?? "Unknown";

// Good: one level, where a statement can't go
<Button variant={isPrimary ? "primary" : "secondary"} />
```

### comments-last-resort (MEDIUM) — @rules/comments-last-resort.md

The default is no comment. Rename, then extract, then — only if the information can't live in the
code — comment. JSDoc only for APIs consumed outside the repo.

```typescript
// Bad: a comment carrying the rule
// Transactions under the policy floor skip written acknowledgment
if (transaction.amount < 250) { ... }

// Good: the rule is the code
if (isBelowAcknowledgmentFloor(transaction)) { ... }
```

### object-calisthenics (MEDIUM) — @rules/object-calisthenics.md

Enforced: one indentation level, no `else`, no abbreviations, small units, one dot per line,
first-class collections. Narrow: wrap primitives (domain values only), max two instance variables
and no getters/setters (classes and services only).

```typescript
// Bad: nested, uses else
function shipIfReady(order: Order) {
  if (order.isPaid) {
    if (!order.isShipped) ship(order);
  } else {
    hold(order);
  }
}

// Good: guard clauses, one level
function shipIfReady(order: Order) {
  if (!order.isPaid) return hold(order);
  if (order.isShipped) return;
  ship(order);
}
```
