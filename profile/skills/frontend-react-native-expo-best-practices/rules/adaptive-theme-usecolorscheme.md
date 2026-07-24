---
title: Build Adaptive Themes with useColorScheme
impact: HIGH
tags: [theming, dark-mode, accessibility]
---

# Build Adaptive Themes with useColorScheme

Drive color theme from system color scheme and central token maps.

## Why

- Supports platform dark mode expectations
- Keeps color decisions centralized and testable
- Improves accessibility in low-light conditions

## Pattern

```ts
import { useColorScheme } from "react-native";

const palette = {
  light: { background: "#ffffff", text: "#111827" },
  dark: { background: "#0b0f14", text: "#f9fafb" },
};

export function useAppTheme() {
  const colorScheme = useColorScheme();
  const isDarkMode = colorScheme === "dark";
  return isDarkMode ? palette.dark : palette.light;
}
```

## Rules

1. Use token maps, not scattered inline color literals.
2. Handle dark and light mode in shared theme helpers.
3. Verify contrast and text scaling in both schemes.
