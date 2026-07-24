---
title: Capture Production Errors with Sentry
impact: CRITICAL
tags: [monitoring, sentry, observability]
---

# Capture Production Errors with Sentry

Integrate Sentry in production builds and capture exceptions with enough context to debug quickly.

## Why

- Mobile failures are hard to reproduce locally
- Stack traces, release tags, and device metadata speed triage
- Detects regressions early after releases and OTA updates

## Pattern

```ts
Sentry.init({
  dsn: process.env.EXPO_PUBLIC_SENTRY_DSN,
  enableNative: true,
});

function handleCheckoutError(error: unknown) {
  Sentry.captureException(error);
}
```

## Rules

1. Initialize monitoring early in app startup.
2. Capture exceptions at feature boundaries and global handlers.
3. Tag releases/build profiles for faster incident correlation.
