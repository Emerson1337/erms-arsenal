---
title: Handle Insets with react-native-safe-area-context
impact: HIGH
tags: [safe-area, layout, ui]
---

# Handle Insets with react-native-safe-area-context

Provide safe-area context globally and build top-level screens with safe-area-aware containers.

## Why

- Prevents clipped UI near notches and home indicators
- Avoids brittle platform-specific padding hacks
- Improves consistency across iOS and Android devices

## Pattern

```tsx
import { SafeAreaProvider, SafeAreaView } from "react-native-safe-area-context";

export function App() {
  return (
    <SafeAreaProvider>
      <SafeAreaView style={{ flex: 1 }} edges={["top", "left", "right"]}>
        <RootLayout />
      </SafeAreaView>
    </SafeAreaProvider>
  );
}
```

## Rules

1. Mount one `SafeAreaProvider` at app root.
2. Use `SafeAreaView` (or inset hooks) in top-level layouts.
3. Avoid hardcoded status bar padding for safe areas.
