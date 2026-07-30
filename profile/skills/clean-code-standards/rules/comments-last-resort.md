---
title: Comments Are a Last Resort
impact: MEDIUM
impactDescription: code readability and maintenance
tags: typescript, javascript, comments, documentation, conventions
---

## Comments Are a Last Resort

The default is **no comment**. Write a comment only when the information genuinely cannot live in
the code, and only after trying to put it there.

### Why

1. **Code is checked, comments aren't** — nothing verifies a comment still matches the code
2. **They go stale silently** — the code changes, the comment doesn't, and now it's actively wrong
3. **Noise buries the real ones** — when most comments say nothing, the important one gets skimmed
4. **A comment often marks a naming problem** — the urge to explain a line usually means the line
   should be named instead

### The Order to Try

When you want to write a comment:

1. **Rename** — a better name for the variable, function, or type
2. **Extract** — pull the logic into a named function or a named constant that states the intent
3. **Then comment** — only if the information is genuinely outside the code (a policy, a vendor bug,
   a decision)

### The Preferred Move: Extract Instead of Explain

```typescript
// Bad: a comment carrying the rule
// Transactions under the policy floor skip written acknowledgment
if (transaction.amount < 250) {
  return { requiresAcknowledgment: false };
}

// Good: the rule is the code
if (isBelowAcknowledgmentFloor(transaction)) {
  return { requiresAcknowledgment: false };
}
```

```typescript
// Bad: a comment explaining a magic number
// API returns cents
let displayAmount = apiAmount / 100;

// Good: the constant says it
const CENTS_PER_DOLLAR = 100;
let displayAmount = apiAmount / CENTS_PER_DOLLAR;
```

### Bad: Comments That Say What the Code Says

```typescript
// Bad: restates the code
// Set the user's name
let userName = user.name;

// Bad: obvious from the code
// Loop through the items
for (let item of items) {
  // Process the item
  processItem(item);
}

// Bad: repeats the function name
// Calculate the total
function calculateTotal(items: Item[]) { ... }

// Bad: describes an assignment
// Create an empty array
let results = [];
```

### Good: The Cases That Survive

Each of these carries information that cannot be expressed in code.

#### An External Rule and Its Source

```typescript
// Reporting threshold is set by the state filing rules, not by us — see docs/compliance.md
const REPORTING_THRESHOLD = 10_000;
```

#### A Workaround for Someone Else's Bug

```typescript
// Safari doesn't support smooth scrolling inside iframes, so it jumps instead
let behavior = isSafari && isInIframe ? "instant" : "smooth";
```

#### Deliberately Unusual Behavior

```typescript
// Intentionally not awaited — analytics must never delay the response
void analytics.track("page_view", { path });
```

#### A Trade-off Someone Would Otherwise Undo

```typescript
// Sequential on purpose: the vendor rate-limits to 1 request/second per key
for (let invoice of invoices) {
  await submit(invoice);
}
```

#### Vendored Code

```typescript
// Vendored from <owner>/<repo> to avoid pulling in the full dependency
function debounce(fn: () => void, wait: number) { ... }
```

#### A TODO With an Owner and an Exit

```typescript
// TODO(#412): delete once the legacy import path is retired
let useLegacyApi = featureFlags.useLegacyApi;
```

A TODO with no ticket and no condition for removal is not a comment — it's a permanent note that
nobody will action. Either file the ticket or fix it now.

### JSDoc: Only for APIs Consumed Outside This Repo

JSDoc on internal exports is duplication. The signature already gives the parameter names and types,
and the function name gives the purpose — so the block adds a second copy that can drift.

```typescript
// Bad: internal helper, JSDoc says nothing the signature doesn't
/**
 * Formats a number as USD currency
 * @param amount - The amount in dollars
 * @returns Formatted string
 */
export function formatCurrency(amount: number): string { ... }

// Good: the signature is the documentation
export function formatCurrency(amount: number): string { ... }
```

Keep JSDoc where readers can't see the source: published packages, shared SDKs, and public API
surfaces where the hover text is the only documentation. Even there, document what the types can't
say — units, ranges, throwing behavior:

```typescript
/**
 * @param amount - dollars, not cents
 * @throws RangeError if amount is negative
 */
export function formatCurrency(amount: number): string { ... }
```

### Summary

| Instead of                            | Do                                      |
| ------------------------------------- | --------------------------------------- |
| A comment explaining what a line does | Rename the variable or function         |
| A comment explaining a condition      | Extract a named predicate function      |
| A comment explaining a number         | Name the constant                       |
| JSDoc on an internal export           | Nothing — the signature covers it       |
| A bare `TODO`                         | `TODO(#id)` with a removal condition    |
| A comment on a policy or a vendor bug | Keep it — this is what comments are for |
