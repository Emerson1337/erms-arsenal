---
title: Use Expo Docs as Source of Truth
impact: CRITICAL
tags: [expo, docs, setup]
---

# Use Expo Docs as Source of Truth

Follow official Expo documentation for project setup, module configuration, updates, security guidance, and distribution workflows.

## Why

- Expo modules evolve quickly between SDK releases
- Official docs reflect current supported APIs and migration paths
- Reduces copy-paste of outdated community snippets

## Pattern

```bash
# Install Expo-first modules with compatible versions
npx expo install expo-router expo-updates expo-splash-screen
```

## Rules

1. Validate new patterns against docs before adding them to the codebase.
2. Prefer Expo-maintained packages when they cover the requirement.
3. Re-check docs during SDK upgrade planning.
