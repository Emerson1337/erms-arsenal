---
title: Prefer Native Accessibility Props
impact: HIGH
tags: [a11y, accessibility, ui]
---

# Prefer Native Accessibility Props

Use React Native accessibility props (`accessibilityRole`, labels, hints, state) on interactive elements.

## Why

- Improves screen-reader navigation and context
- Produces better parity across iOS VoiceOver and Android TalkBack
- Encourages test selectors that match real semantics

## Pattern

```tsx
<Pressable
  accessibilityRole="button"
  accessibilityLabel="Submit order"
  accessibilityHint="Submits your current cart"
  accessibilityState={{ busy: isLoading }}
  onPress={handleSubmit}
>
  <Text>Submit</Text>
</Pressable>
```

## Rules

1. Add role/label for all custom interactive controls.
2. Prefer semantic queries in tests over unstable class/text selectors.
3. Respect dynamic text size and screen-reader focus order.
