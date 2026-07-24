---
title: Gate OTA Updates with Runtime Version
impact: CRITICAL
tags: [eas-update, ota, runtime-version]
---

# Gate OTA Updates with Runtime Version

Pin runtime compatibility so OTA bundles only reach builds that can execute them.

## Why

- Prevents JS updates from targeting incompatible native binaries
- Enables safer rollout and rollback by channel
- Reduces production crashes from native/JS mismatch

## Pattern

```json
{
  "expo": {
    "runtimeVersion": {
      "policy": "appVersion"
    },
    "updates": {
      "url": "https://u.expo.dev/your-project-id"
    }
  }
}
```

```bash
# Publish only to preview channel first
npx eas update --branch preview --message "checkout fix"
```

## Rules

1. Configure runtime version policy before enabling OTA at scale.
2. Roll out to non-production branch/channel first.
3. Promote to production only after smoke testing the exact update.
