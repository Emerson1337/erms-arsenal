---
title: Store Secrets in SecureStore
impact: CRITICAL
tags: [security, auth, storage]
---

# Store Secrets in SecureStore

Use `expo-secure-store` for session tokens, refresh tokens, and other secrets.

## Why

- Uses platform secure storage primitives
- Reduces accidental secret exposure in plain storage
- Better baseline security for compromised device scenarios

## Incorrect

```ts
await AsyncStorage.setItem("refresh_token", refreshToken);
```

## Correct

```ts
import * as SecureStore from "expo-secure-store";

await SecureStore.setItemAsync("refresh_token", refreshToken);
const token = await SecureStore.getItemAsync("refresh_token");
```

## Rules

1. Never store auth tokens in AsyncStorage.
2. Keep only non-sensitive UI preferences in AsyncStorage.
3. Clear secure values during logout and session invalidation.
