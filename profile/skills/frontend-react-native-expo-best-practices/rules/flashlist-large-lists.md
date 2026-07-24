---
title: Use FlashList for Large Collections
impact: CRITICAL
tags: [performance, lists, flashlist]
---

# Use FlashList for Large Collections

For medium and large datasets, prefer `@shopify/flash-list` with stable keys and memoized rows.

## Why

- Better virtualization and lower memory pressure than default FlatList in large lists
- Smoother scroll performance on lower-end devices
- More predictable rendering cost

## Incorrect

```tsx
<FlatList
  data={orders}
  renderItem={({ item }) => <OrderRow item={item} />}
  keyExtractor={(item) => Math.random().toString()}
/>
```

## Correct

```tsx
import { FlashList } from "@shopify/flash-list";

const renderOrderRow = useCallback(
  ({ item }: { item: Order }) => <OrderRow item={item} />,
  [],
);

<FlashList
  data={orders}
  estimatedItemSize={72}
  renderItem={renderOrderRow}
  keyExtractor={(item) => item.id}
/>;
```

## Rules

1. Use stable keys from backend identifiers.
2. Memoize `renderItem` and heavy row components.
3. Provide `estimatedItemSize` for better list virtualization.
