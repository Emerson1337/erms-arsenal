---
title: Serve Locales from a Resource Route
impact: HIGH
tags: [i18n, routes, caching]
---

# Serve Locales from a Resource Route

Expose `/api/locales/:lng/:ns` to load translation resources with caching.

## Pattern

```ts
// app/routes/api.locales.$lng.$ns.ts
import { data } from "react-router";
import { cacheHeader } from "pretty-cache-header";
import resources from "~/locales";
import type { Route } from "./+types/api.locales.$lng.$ns";

type Language = keyof typeof resources;

function isLanguage(value: string | undefined): value is Language {
  return value !== undefined && value in resources;
}

function isNamespaceOf<TNamespaces extends object>(
  namespaces: TNamespaces,
  value: string | undefined,
): value is Extract<keyof TNamespaces, string> {
  return value !== undefined && value in namespaces;
}

export async function loader({ params }: Route.LoaderArgs) {
  if (!isLanguage(params.lng)) {
    return data({ error: "Unknown language" }, { status: 400 });
  }

  const namespaces = resources[params.lng];

  if (!isNamespaceOf(namespaces, params.ns)) {
    return data({ error: "Unknown namespace" }, { status: 400 });
  }

  const headers = new Headers();
  if (process.env.NODE_ENV === "production") {
    headers.set(
      "Cache-Control",
      cacheHeader({
        maxAge: "5m",
        sMaxage: "1d",
        staleWhileRevalidate: "7d",
        staleIfError: "7d",
      }),
    );
  }

  return data(namespaces[params.ns], { headers });
}
```

## Rules

1. Validate `lng` and `ns` before returning data
2. Cache locale resources in production
3. Keep the route aligned with client `loadPath`
