---
title: Define a Stable Deep Link Contract
impact: HIGH
tags: [deep-linking, notifications, routing]
---

# Define a Stable Deep Link Contract

Treat deep links as a public API and keep link formats versioned and stable.

## Why

- Push notifications and emails depend on route stability
- Reduces broken links after navigation refactors
- Improves analytics consistency

## Pattern

```ts
import * as Linking from "expo-linking";
import { router } from "expo-router";

const orderUrl = Linking.createURL("/orders/123");

function openOrder(orderId: string) {
  router.push(`/orders/${orderId}`);
}
```

## Rules

1. Choose canonical paths for key resources (`/orders/:id`, `/profile`).
2. Parse and validate params before using them.
3. Add E2E checks for the most important deep links.
