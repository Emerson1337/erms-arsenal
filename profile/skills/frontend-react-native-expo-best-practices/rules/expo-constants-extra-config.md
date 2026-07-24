---
title: Read Runtime Config from expo-constants
impact: HIGH
tags: [expo-constants, config, environment]
---

# Read Runtime Config from expo-constants

Expose non-secret runtime configuration in `app.config.ts` and access it via `expo-constants`.

## Why

- Keeps build-time and runtime config in sync
- Avoids hardcoding environment URLs in component files
- Works predictably across iOS, Android, and EAS updates

## Pattern

```ts
// app.config.ts
export default {
  expo: {
    extra: {
      apiUrl: process.env.EXPO_PUBLIC_API_URL,
    },
  },
};

// src/lib/config.ts
import Constants from "expo-constants";

export const runtimeConfig = {
  apiUrl: Constants.expoConfig?.extra?.apiUrl as string,
};
```

## Rules

1. Keep secrets out of public runtime config.
2. Access config through a single helper module.
3. Validate required config keys at app startup.
