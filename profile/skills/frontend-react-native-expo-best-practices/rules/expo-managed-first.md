---
title: Prefer Expo Managed Workflow First
impact: CRITICAL
tags: [expo, workflow, architecture]
---

# Prefer Expo Managed Workflow First

Start with Expo managed workflow and only move to prebuild/native project edits when a concrete requirement cannot be met with Expo modules.

## Why

- Managed apps ship faster and stay easier to upgrade
- Fewer native build failures and less iOS/Android divergence
- Expo SDK upgrades remain predictable

## Pattern

```bash
# Preferred baseline
npx create-expo-app@latest mobile

# Add Expo-native integrations before considering ejecting
npx expo install expo-notifications expo-location expo-camera

# Only if a native requirement is unavoidable
npx expo prebuild
```

## Rules

1. Default to managed workflow for new projects.
2. Document the requirement before introducing native project customization.
3. Re-evaluate if an official Expo module can replace custom native code.
