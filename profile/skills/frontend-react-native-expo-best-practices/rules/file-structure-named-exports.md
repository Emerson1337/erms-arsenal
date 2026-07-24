---
title: Use Predictable File Structure and Named Exports
impact: HIGH
tags: [architecture, naming, exports]
---

# Use Predictable File Structure and Named Exports

Structure component files consistently and prefer named exports to improve discoverability and refactoring safety.

## Why

- Reduces merge conflicts and file-level entropy
- Makes imports easier to grep and auto-refactor
- Keeps files readable as complexity grows

## Pattern

```tsx
interface ProfileCardProps {
  userId: string;
  isLoading: boolean;
}

export function ProfileCard({ userId, isLoading }: ProfileCardProps) {
  if (isLoading) return <LoadingCard />;
  return <ProfileBody userId={userId} />;
}

function ProfileBody({ userId }: { userId: string }) {
  return <View>{/* ... */}</View>;
}

function createTrackingPayload(userId: string) {
  return { userId };
}
```

## Rules

1. Use kebab-case directories (`components/auth-wizard`).
2. Prefer named exports for components and utilities.
3. Order file content as: exported component, subcomponents, helpers, static values, interfaces.
