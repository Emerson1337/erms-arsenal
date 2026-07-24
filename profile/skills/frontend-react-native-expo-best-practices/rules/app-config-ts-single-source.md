---
title: Centralize Environment Config in app.config.ts
impact: HIGH
tags: [expo, config, environment]
---

# Centralize Environment Config in app.config.ts

Keep app identity, runtime settings, and environment-based values in `app.config.ts` instead of scattering config across scripts and constants.

## Why

- One place controls iOS/Android identifiers and update metadata
- Reduces environment drift between CI and local machines
- Makes release config auditable

## Incorrect

```ts
// Scattered values in random files
export const API_URL = "https://api.prod.example.com";
// bundle identifiers set in CI only
```

## Correct

```ts
import "dotenv/config";

export default {
  expo: {
    name: process.env.APP_NAME ?? "Acme",
    slug: "acme-mobile",
    ios: { bundleIdentifier: process.env.IOS_BUNDLE_ID },
    android: { package: process.env.ANDROID_PACKAGE },
    extra: {
      apiUrl: process.env.EXPO_PUBLIC_API_URL,
    },
  },
};
```

## Rules

1. Read environment variables in `app.config.ts`.
2. Keep platform identifiers and update config in that file.
3. Expose only non-secret client runtime values via `extra`/`EXPO_PUBLIC_*`.
