---
title: One Ternary Level, Never Chained
impact: MEDIUM
impactDescription: readability of conditional logic
tags: typescript, javascript, readability, conventions
---

## One Ternary Level, Never Chained

One level is the hard ceiling. A chained or nested ternary is never acceptable — not when it's
short, not when it's formatted across lines, not in JSX.

A single ternary is good where a statement can't go or would be noise: a JSX prop, a `className`,
a short inline default, a one-word label. The moment a second `?` appears in the same expression,
stop and pick one of the replacements below.

### Why

1. **Chains have no visible structure** — an `if` ladder shows its branches down the left margin; a
   ternary chain hides them inside one expression that has to be read start to finish
2. **The pairing is invisible** — with nesting you have to count `?` against `:` to know which
   branch you're in
3. **Diffs get bad** — adding one case reflows the whole expression, so review can't see what changed
4. **Chains attract more cases** — every new status gets appended, and nobody stops to restructure

### Good: One Level

```tsx
<Button variant={isPrimary ? "primary" : "secondary"} />

let greeting = user.name ? `Hi ${user.name}` : "Hi there";
```

Two independent single-level ternaries in one template literal are still one level each — fine:

```tsx
<button className={`btn ${isActive ? "btn-active" : ""} ${isDisabled ? "btn-disabled" : ""}`}>
```

### Bad: Chained

```typescript
// Bad: four cases in one expression
let label =
  status === "open"
    ? "Open"
    : status === "closed"
      ? "Closed"
      : status === "draft"
        ? "Draft"
        : "Unknown";
```

### Bad: Nested in a Branch

```typescript
// Bad: which branch is `y` in?
let value = isEnabled ? (hasQuota ? nextItem : fallbackItem) : null;
```

### Bad: Branches That Are Side Effects

```typescript
// Bad: nothing is being assigned — this is an if
isValid ? save(order) : reportInvalid(order);
```

## Replacements, in Order of Preference

### 1. A Lookup Map — for Value-to-Value Mapping

The usual fix for a chain. Cases become data, and adding one is a one-line diff.

```typescript
const STATUS_LABELS: Record<OrderStatus, string> = {
  open: "Open",
  closed: "Closed",
  draft: "Draft",
};

let label = STATUS_LABELS[status] ?? "Unknown";
```

### 2. Early Returns in an Extracted Function

For conditions that aren't a straight key lookup. Pairs with the guard-clause rule in
`@rules/object-calisthenics.md`.

```typescript
function shipmentLabel(shipment: Shipment): string {
  if (shipment.deliveredAt) return "Delivered";
  if (shipment.isDelayed) return "Delayed";
  if (shipment.shippedAt) return "In transit";
  return "Preparing";
}
```

In JSX, extract a component or a small `renderX()` function rather than nesting ternaries in markup:

```tsx
// Bad: nested in markup
{isLoading ? <Spinner /> : error ? <Error error={error} /> : <List items={items} />}

// Good: the branches are statements again
function OrderList({ isLoading, error, items }: OrderListProps) {
  if (isLoading) return <Spinner />;
  if (error) return <ErrorMessage error={error} />;
  return <List items={items} />;
}
```

### 3. `??` or `||` — for a Default

Not a conditional at all, so it doesn't count against the ceiling.

```typescript
// Bad
let pageSize = params.pageSize ? params.pageSize : 25;

// Good
let pageSize = params.pageSize ?? 25;
```

### 4. A Plain `if`

Wanting to save two lines is not a reason to reach for a ternary.

### Summary

| Instead of                          | Use                                             |
| ----------------------------------- | ----------------------------------------------- |
| Chained ternary over one value      | `Record` lookup map + `??` for the fallback     |
| Nested ternary                      | Extracted function with early returns           |
| Nested ternary inside JSX           | A component or `renderX()` with early returns   |
| `cond ? value : defaultValue`       | `value ?? defaultValue`                         |
| `cond ? doA() : doB()`              | `if` / `else`                                   |
| One ternary in a prop or a label    | Keep it — that's the level this rule allows     |
