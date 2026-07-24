---
title: Optimize Images with expo-image
impact: HIGH
tags: [performance, images, expo-image]
---

# Optimize Images with expo-image

Use `expo-image` for remote images with explicit dimensions and cache policy.

## Why

- Better caching behavior and decoding performance
- Prevents layout shift from unknown image sizes
- Cleaner placeholder/transition handling

## Pattern

```tsx
import { Image } from "expo-image";

<Image
  source={{ uri: user.avatarUrl }}
  style={{ width: 56, height: 56, borderRadius: 28 }}
  contentFit="cover"
  placeholder={blurhash}
  transition={150}
  cachePolicy="memory-disk"
/>;
```

## Rules

1. Set width/height for all non-fill images.
2. Use placeholders for slow network scenarios.
3. Avoid loading full-resolution assets into tiny containers.
