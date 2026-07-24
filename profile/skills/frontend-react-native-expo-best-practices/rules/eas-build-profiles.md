---
title: Separate EAS Build Profiles
impact: CRITICAL
tags: [eas, ci, release]
---

# Separate EAS Build Profiles

Define distinct `development`, `preview`, and `production` EAS build profiles with clear intent.

## Why

- Prevents shipping debug/dev clients to production users
- Enables QA testing with preview artifacts
- Keeps CI commands predictable and repeatable

## Pattern

```json
{
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal"
    },
    "preview": {
      "distribution": "internal"
    },
    "production": {
      "autoIncrement": true
    }
  }
}
```

## Rules

1. Use development profile for local/dev client workflows only.
2. Use preview profile for QA and stakeholder validation.
3. Use production profile for store-ready releases.
