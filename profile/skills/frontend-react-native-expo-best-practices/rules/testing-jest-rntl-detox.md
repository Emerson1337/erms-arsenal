---
title: Layer Tests with Jest, RNTL, and Detox
impact: HIGH
tags: [testing, jest, detox, rntl]
---

# Layer Tests with Jest, RNTL, and Detox

Use Jest + React Native Testing Library for fast component and logic tests, and Detox for critical end-to-end device flows.

## Why

- Fast feedback for core rendering and behavior checks
- Device-level validation for navigation, permissions, and native bridges
- Better confidence before store submissions and OTA rollouts

## Pattern

```ts
// Jest + RNTL
it("shows loading state", () => {
  render(<OrdersScreen isLoading />);
  expect(screen.getByText("Loading orders")).toBeTruthy();
});
```

```ts
// Detox
it("completes login flow", async () => {
  await element(by.id("email-input")).typeText("test@example.com");
  await element(by.id("password-input")).typeText("password123");
  await element(by.id("login-button")).tap();
  await expect(element(by.text("Dashboard"))).toBeVisible();
});
```

## Rules

1. Cover business-critical flows with Detox.
2. Keep unit tests deterministic and low-mock.
3. Run at least one production-like E2E pass before release.
