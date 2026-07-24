---
title: Use Expo Router File-Based Routing
impact: HIGH
tags: [expo-router, navigation, routing]
---

# Use Expo Router File-Based Routing

Model navigation through Expo Router folders and layout files so route hierarchy is visible in the filesystem.

## Why

- Route ownership is obvious from file paths
- Nested layouts reduce duplicated navigation setup
- Deep links map cleanly to route paths

## Pattern

```tsx
// app/_layout.tsx
import { Stack } from "expo-router";

export default function RootLayout() {
  return <Stack screenOptions={{ headerBackTitleVisible: false }} />;
}

// app/orders/[orderId].tsx
import { useLocalSearchParams } from "expo-router";

export default function OrderDetailsScreen() {
  const { orderId } = useLocalSearchParams<{ orderId: string }>();
  return <OrderDetails orderId={orderId} />;
}
```

## Rules

1. Keep route files under `app/` and use nested `_layout.tsx` files.
2. Use typed params (`useLocalSearchParams`) for dynamic segments.
3. Avoid mixing multiple navigation frameworks in the same app.
