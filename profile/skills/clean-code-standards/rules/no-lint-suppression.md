---
title: Never Suppress a Linter or Type Checker
impact: HIGH
impactDescription: keeps every rule the team agreed on actually enforced
tags: eslint, typescript, tooling, conventions
---

## Never Suppress a Linter or Type Checker

No `eslint-disable`, no `@ts-ignore`, no `@ts-expect-error`, no `prettier-ignore`, no `--no-verify`,
no `.skip` or `.only` left in a test file. Fix the code instead.

### Why

1. **A rule fires because someone already hit the bug it prevents** — silencing it re-opens that bug
2. **A suppression outlives its reason** — the comment stays after the code around it changes, and
   nobody can tell whether it's still needed
3. **It's an unreviewed exception** — a config change is a team decision; an inline comment is one
   person deciding for everyone, in a file nobody re-reads
4. **File-level disables are unbounded** — one line at the top uncovers hundreds of lines below it,
   including code written months later
5. **A green check that was made green by hand isn't a signal anymore**

### Bad: Silencing the Message

```typescript
// Bad: the dependency really is missing, and the stale closure is a real bug
// eslint-disable-next-line react-hooks/exhaustive-deps
useEffect(() => { sync(orderId); }, []);

// Bad: the error is that this can be undefined
// @ts-ignore
return user.profile.avatarUrl;

// Bad: uncovers the whole file, forever
/* eslint-disable @typescript-eslint/no-explicit-any */
```

### Good: Fix What It's Pointing At

```typescript
// Good: declare the dependency the effect actually uses
useEffect(() => { sync(orderId); }, [orderId]);

// Good: handle the case the type describes
if (!user.profile) return null;
return user.profile.avatarUrl;
```

### When the Rule Is Genuinely Wrong Here

Change the **eslint config**, not the call site. A config change is reviewed, applies consistently,
and can be found later. Scope it as narrowly as the situation deserves — an `overrides` entry for
one directory beats turning a rule off repository-wide.

```javascript
// eslint.config.js — reviewed, discoverable, scoped
{
  files: ["**/*.test.ts"],
  rules: { "@typescript-eslint/no-non-null-assertion": "off" },
}
```

### If a Suppression Is Truly Unavoidable

Rare, and it comes with all four of these or it doesn't land:

1. The narrowest scope — `next-line`, never file-level
2. The specific rule named — never a bare `eslint-disable`
3. A one-line reason stating what makes this case different
4. `@ts-expect-error` rather than `@ts-ignore`, so it fails once the underlying issue is fixed

```typescript
// Upstream types mark `duration` required; the API omits it for live streams.
// Remove when the vendor ships types matching their own docs.
// @ts-expect-error - vendor types disagree with the runtime payload
let duration = media.duration;
```

### For the Agent

**Never add a suppression to make a check pass.** If a lint or type error can't be fixed inside the
task's scope, report the blocker and what fixing it would take. A passing build that was made to
pass by silencing a rule is a worse outcome than a reported failure.

### Summary

| Instead of                        | Do                                                |
| --------------------------------- | ------------------------------------------------- |
| `eslint-disable-next-line`        | Fix the code the rule is pointing at              |
| `/* eslint-disable */` at the top | Never — scope it or fix it                        |
| `@ts-ignore`                      | Fix the type, or `@ts-expect-error` with a reason |
| Turning a rule off inline         | Change `eslint.config.js`, scoped by `files`      |
| `git commit --no-verify`          | Fix the hook failure                              |
| `.only` / `.skip` left in a test  | Run the whole suite; delete or fix the test       |
