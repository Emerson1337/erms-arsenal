---
name: frontend-react-native-expo-best-practices
description: React Native with Expo architecture and performance best practices. Use when building, reviewing, or refactoring Expo apps, including TypeScript conventions, navigation, state, device APIs, safe areas, animations, testing, security, builds, and OTA release workflows.
---

# React Native Expo Best Practices

Production-oriented patterns for building React Native apps with Expo. Contains 20 rules across 10 categories focused on maintainable architecture, predictable runtime behavior, performance, accessibility, and safe release workflows.

## When to Apply

Reference these guidelines when:

- Starting a new Expo app
- Refactoring an existing React Native codebase
- Defining TypeScript and file-structure conventions
- Integrating device features (camera, location, notifications)
- Optimizing list, image, and animation performance
- Implementing safe-area handling, dark mode, and accessibility
- Setting up validation, monitoring, and mobile testing strategy
- Setting up EAS Build and EAS Update pipelines
- Reviewing Expo app code for production readiness

## Rules Summary

### Architecture (CRITICAL)

#### expo-docs-source-of-truth - @rules/expo-docs-source-of-truth.md

Use Expo documentation as the source of truth for setup, configuration, and deployment decisions.

```bash
npx expo install expo-router expo-splash-screen expo-secure-store
```

#### expo-managed-first - @rules/expo-managed-first.md

Prefer Expo managed workflow by default and only eject/prebuild for unavoidable native requirements.

```bash
# Managed workflow (preferred)
npx create-expo-app@latest mobile

# Prebuild only when you truly need native project edits
npx expo prebuild
```

#### app-config-ts-single-source - @rules/app-config-ts-single-source.md

Use `app.config.ts` as the single source of truth for environment-aware app config.

```ts
import "dotenv/config";

export default {
  expo: {
    name: process.env.APP_NAME ?? "Acme",
    ios: { bundleIdentifier: process.env.IOS_BUNDLE_ID },
    android: { package: process.env.ANDROID_PACKAGE },
  },
};
```

#### expo-constants-extra-config - @rules/expo-constants-extra-config.md

Read runtime-safe configuration from `Constants.expoConfig?.extra`.

```ts
const apiUrl = Constants.expoConfig?.extra?.apiUrl;
```

### TypeScript & Project Conventions (HIGH)

#### file-structure-named-exports - @rules/file-structure-named-exports.md

Use predictable file ordering and named exports for components.

```tsx
export function ProfileCard(props: ProfileCardProps) {
  return <View />;
}
```

#### typescript-interfaces-no-enums - @rules/typescript-interfaces-no-enums.md

Prefer interfaces and object maps over `type` unions and `enum` defaults.

```ts
interface UserProfile {
  id: string;
  isActive: boolean;
}
```

### Navigation (HIGH)

#### expo-router-file-based-routing - @rules/expo-router-file-based-routing.md

Use Expo Router file-based routing to keep navigation structure explicit and colocated with screens.

```tsx
// app/(tabs)/_layout.tsx
import { Tabs } from "expo-router";

export default function TabLayout() {
  return <Tabs screenOptions={{ headerShown: false }} />;
}
```

#### deep-link-contract - @rules/deep-link-contract.md

Define and test deep link contracts early so push notifications and external links remain stable.

```ts
import * as Linking from "expo-linking";

const url = Linking.createURL("/orders/123");
```

### UI, Safe Areas, and Accessibility (HIGH)

#### safe-area-context-first - @rules/safe-area-context-first.md

Wrap the app with `SafeAreaProvider` and use `SafeAreaView` for inset-aware layouts.

```tsx
<SafeAreaProvider>
  <SafeAreaView style={{ flex: 1 }}>
    <RootNavigation />
  </SafeAreaView>
</SafeAreaProvider>
```

#### adaptive-theme-usecolorscheme - @rules/adaptive-theme-usecolorscheme.md

Drive light/dark theme from `useColorScheme` and central theme tokens.

```ts
const colorScheme = useColorScheme();
const isDarkMode = colorScheme === "dark";
```

#### accessibility-native-props-first - @rules/accessibility-native-props-first.md

Prefer native accessibility props and role semantics over ad-hoc test-only labels.

```tsx
<Pressable accessibilityRole="button" accessibilityLabel="Save profile" />
```

### Performance (CRITICAL)

#### flashlist-large-lists - @rules/flashlist-large-lists.md

Use `FlashList` for medium/large datasets and memoize row renderers.

```tsx
<FlashList
  data={orders}
  estimatedItemSize={72}
  keyExtractor={(item) => item.id}
  renderItem={renderOrderRow}
/>
```

#### expo-image-caching - @rules/expo-image-caching.md

Use `expo-image` with explicit sizing and caching policies instead of unbounded `<Image />` usage.

```tsx
<Image source={avatarUrl} style={{ width: 48, height: 48 }} contentFit="cover" cachePolicy="memory-disk" />
```

#### reanimated-gesture-primitives - @rules/reanimated-gesture-primitives.md

Use `react-native-reanimated` and `react-native-gesture-handler` for high-frequency interactions.

```tsx
const gesture = Gesture.Pan().onUpdate((event) => {
  translateX.value = event.translationX;
});
```

### State and Data (HIGH)

#### reducer-context-for-shared-state - @rules/reducer-context-for-shared-state.md

Use `useReducer` + Context for shared app state and keep local `useState` scoped to local UI concerns.

```ts
const [state, dispatch] = useReducer(reducer, initialState);
```

#### react-query-server-state - @rules/react-query-server-state.md

Use React Query for server state, caching, retries, and deduplication.

```ts
const profileQuery = useQuery({ queryKey: ["profile"], queryFn: fetchProfile });
```

#### appstate-query-invalidation - @rules/appstate-query-invalidation.md

Reconnect and refresh stale server state when the app returns to foreground.

```ts
AppState.addEventListener("change", (state) => {
  if (state === "active") queryClient.invalidateQueries();
});
```

### Validation, Error Handling, and Observability (CRITICAL)

#### zod-validated-boundaries - @rules/zod-validated-boundaries.md

Validate API payloads and critical inputs with Zod at app boundaries.

```ts
const parsed = UserSchema.safeParse(payload);
if (!parsed.success) return null;
```

#### sentry-error-monitoring - @rules/sentry-error-monitoring.md

Capture runtime exceptions and key diagnostics in Sentry for production builds.

```ts
Sentry.captureException(error);
```

### Device APIs & Security (HIGH)

#### permissions-just-in-time - @rules/permissions-just-in-time.md

Request permissions at the moment of use, not at app startup.

```ts
const { status } = await Location.requestForegroundPermissionsAsync();
if (status !== "granted") return;
```

#### secure-store-secrets - @rules/secure-store-secrets.md

Store tokens and secrets in `expo-secure-store`, never in AsyncStorage.

```ts
await SecureStore.setItemAsync("session_token", token);
```

### Testing (HIGH)

#### testing-jest-rntl-detox - @rules/testing-jest-rntl-detox.md

Use Jest + React Native Testing Library for unit/integration and Detox for critical device flows.

```ts
test("shows error state", async () => {
  render(<ProfileScreen />);
  expect(await screen.findByText("Try again")).toBeTruthy();
});
```

### Build, Update, and Release (CRITICAL)

#### eas-build-profiles - @rules/eas-build-profiles.md

Separate `development`, `preview`, and `production` build profiles in `eas.json`.

```json
{
  "build": {
    "development": { "developmentClient": true },
    "preview": {},
    "production": { "autoIncrement": true }
  }
}
```

#### eas-update-runtime-version - @rules/eas-update-runtime-version.md

Pin runtime versions and release OTA updates per channel/branch to avoid incompatible updates.

```json
{
  "expo": {
    "runtimeVersion": { "policy": "appVersion" },
    "updates": { "url": "https://u.expo.dev/<project-id>" }
  }
}
```

## Key Files

- `app/` - Expo Router routes and layouts
- `app.config.ts` - Dynamic Expo app configuration
- `eas.json` - Build profile definitions
- `package.json` - Scripts and dependency constraints
- `src/components/` - Reusable UI components (kebab-case directories)
- `src/features/` - Feature modules and UI/state boundaries
