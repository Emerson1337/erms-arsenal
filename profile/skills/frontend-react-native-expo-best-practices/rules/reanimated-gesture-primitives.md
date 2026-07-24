---
title: Use Reanimated and Gesture Handler for Interactive Motion
impact: HIGH
tags: [performance, animation, gestures]
---

# Use Reanimated and Gesture Handler for Interactive Motion

Use Reanimated shared values and gesture-handler primitives for high-frequency animations and gestures.

## Why

- Offloads animation work from the JS thread
- Produces smoother interactions under load
- Avoids brittle manual event/animation plumbing

## Pattern

```tsx
const translateX = useSharedValue(0);

const panGesture = Gesture.Pan().onUpdate((event) => {
  translateX.value = event.translationX;
});

const animatedStyle = useAnimatedStyle(() => ({
  transform: [{ translateX: translateX.value }],
}));
```

## Rules

1. Use Reanimated for gesture-driven motion.
2. Keep animated values in shared values, not React state.
3. Use `GestureDetector` + composed gestures for complex interactions.
