---
title: Request Permissions Just In Time
impact: HIGH
tags: [permissions, privacy, device-apis]
---

# Request Permissions Just In Time

Ask for device permissions when users initiate the related action, not on first app launch.

## Why

- Higher permission acceptance rates
- Better privacy UX and trust
- Fewer blocked onboarding funnels

## Incorrect

```ts
// App startup
await Location.requestForegroundPermissionsAsync();
await Camera.requestCameraPermissionsAsync();
```

## Correct

```ts
async function startLocationFlow() {
  const { status } = await Location.requestForegroundPermissionsAsync();
  if (status !== "granted") return;
  const current = await Location.getCurrentPositionAsync({});
  return current;
}
```

## Rules

1. Explain why the permission is needed before prompting.
2. Request only the minimum permission scope required.
3. Handle denied states with clear fallback UX.
