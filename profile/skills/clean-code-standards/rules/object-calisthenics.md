---
title: Object Calisthenics at Medium Effort
impact: MEDIUM
impactDescription: structure, reusability, and how small each unit stays
tags: typescript, javascript, structure, readability, conventions
---

## Object Calisthenics at Medium Effort

Object calisthenics is nine rules for keeping units small and intent visible. Applied at full
strength it fights idiomatic TypeScript and React. **Medium effort** means six of the nine are
enforced everywhere, and three are applied only where they pay off.

### Why

1. **Small units are reusable** — a function that does one thing gets called from a second place; a
   function that does four never does
2. **Flat code is readable in one pass** — nesting forces the reader to hold each condition in mind
3. **Explicit names remove the need for comments** — see `@rules/comments-last-resort.md`
4. **Loose coupling survives refactors** — code that reaches through three objects breaks when any
   of the three changes

## Enforce Everywhere

### 1. One Level of Indentation per Function

If a second level appears, extract it or invert the condition.

```typescript
// Bad: three levels
function processOrders(orders: Order[]) {
  for (let order of orders) {
    if (order.isPaid) {
      if (!order.isShipped) {
        ship(order);
      }
    }
  }
}

// Good: one level each
function processOrders(orders: Order[]) {
  for (let order of orders) {
    shipIfReady(order);
  }
}

function shipIfReady(order: Order) {
  if (!order.isPaid) return;
  if (order.isShipped) return;
  ship(order);
}
```

### 2. Don't Use else

Guard clauses. Handle the exceptional case and return, leaving the main path unindented.

```typescript
// Bad
function priceFor(customer: Customer): number {
  if (customer.isMember) {
    return MEMBER_PRICE;
  } else {
    return LIST_PRICE;
  }
}

// Good
function priceFor(customer: Customer): number {
  if (customer.isMember) return MEMBER_PRICE;
  return LIST_PRICE;
}
```

For more than two outcomes, use a lookup map or a sequence of early returns — never a ternary
chain (`@rules/ternary-one-level-max.md`).

### 3. Don't Abbreviate

`request`, not `req`. `index`, not `idx`. `configuration`, not `cfg`. If a name is getting long
because the thing does several jobs, split the thing.

Exceptions: the conventional loop counter `i`, and established domain abbreviations the whole team
reads instantly (`url`, `id`, `http`).

```typescript
// Bad
function h(e: Event, ctx: Ctx) { ... }

// Good
function handleSubmit(event: Event, context: RequestContext) { ... }
```

### 4. Keep Every Unit Small

A function does one thing — around 20 lines is the point to look for a seam. A file stays
navigable; when it needs a table of contents, it's two files.

### 5. One Dot per Line (Law of Demeter)

Don't reach through a chain of objects. Ask for what you need.

```typescript
// Bad: knows the shape of three objects
function label(order: Order) {
  return order.customer.address.city.toUpperCase();
}

// Good: takes what it uses
function label(city: string) {
  return city.toUpperCase();
}
```

Fluent APIs and optional chaining on your own data (`user?.name`) are not what this rule is about —
it's about depending on the internal structure of things you don't own.

### 6. First-Class Collections

When a collection travels together with behavior, give it a type instead of passing a bare array
plus a pile of loose helpers.

```typescript
// Bad: the array and its rules are separate
function totalOf(items: LineItem[]) { ... }
function taxableOf(items: LineItem[]) { ... }
function withoutVoided(items: LineItem[]) { ... }

// Good: one thing that owns the rules
class Basket {
  constructor(private readonly items: readonly LineItem[]) {}

  total(): Money { ... }
  taxable(): Basket { ... }
  withoutVoided(): Basket { ... }
}
```

A plain array is still the right answer when there's no behavior attached. This rule is about
collections that have grown rules.

## Apply Narrowly

These three are where full-strength calisthenics stops paying for itself in TypeScript.

### 7. Wrap Primitives — for Domain Values Only

Brand IDs, money, and units, where mixing them up is a real bug. Not every string.

```typescript
// Worth it: these are not interchangeable
type UserId = string & { readonly __brand: "UserId" };
type OrderId = string & { readonly __brand: "OrderId" };

// Not worth it: a label is a string
type Label = string & { readonly __brand: "Label" };
```

### 8. No More Than Two Instance Variables — Classes and Services Only

Apply to classes and services, where it's a genuine signal that one object is doing two jobs.
**Do not apply** to props objects, Zod-derived types, loader data, or config records — those are
data shapes, and the `frontend-*` skills prescribe them with many fields on purpose.

### 9. No Getters or Setters — Classes and Services Only

Behavior on the object, not accessors that let callers do the work outside it. Same exclusions as
rule 8: a props object with fields is not a violation, and React state setters are the framework's
API, not a getter/setter pair.

### Summary

| Rule                        | At medium effort              | The TypeScript move                        |
| --------------------------- | ----------------------------- | ------------------------------------------ |
| One indentation level       | Enforced                      | Extract a function; invert the condition   |
| No `else`                   | Enforced                      | Guard clauses and early returns            |
| Don't abbreviate            | Enforced                      | Full words; split names that get long      |
| Keep units small            | Enforced                      | ~20-line functions, navigable files        |
| One dot per line            | Enforced                      | Pass the value, not the object graph       |
| First-class collections     | Enforced when behavior exists | A type that owns the collection's rules    |
| Wrap primitives            | Domain values only            | Branded types for IDs, money, units        |
| Max two instance variables   | Classes and services only     | Not props, Zod types, or config records    |
| No getters or setters       | Classes and services only     | Behavior on the object, not accessors      |
