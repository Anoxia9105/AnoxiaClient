# Provider Defensive Contract

## Goal
Unify provider behavior to avoid UI crashes caused by null/throw in query paths.

## Query Provider Rules
- Single-object query: return nullable object (`T?`), and return `null` when not found.
- Collection query: return empty collection (`[]`/`{}`), do not return `null` by default.
- Never throw business exceptions in query providers.
- Loading state should be driven by upstream `AsyncValue` providers, not by `null` sentinel values.

## Mutation/Command Provider Rules
- Commands can throw and let caller handle `AsyncError` when needed.
- For non-critical side effects, prefer degrade-and-log over crash.

## Current Implemented Scope
- Room lookup related query providers (`currentRoom`, room entry, reconnect compensation) use null-safe lookup helpers.
- Room filtered list query is non-null (`List<ChatRoomVO>`), and returns empty list during loading/error fallback; initial loading skeleton is controlled by `roomListServiceProvider` state.
- A provider-layer scan has been completed in `framework/provider`: no remaining query providers are using `firstWhere`/`singleWhere` throw-paths for room lookup.

## Review Checklist For New Providers
- If return type is collection, do not use nullable collection type unless it is truly tri-state and documented.
- If lookup misses, return `null` (single object) or empty collection (list/map/set).
- Do not encode loading with `null` in query providers; use upstream `AsyncValue` loading state.

## Local Automated Check
- Run: `powershell -ExecutionPolicy Bypass -File tools/check_provider_defensive_contract.ps1`
- Scope: `lib/framework/provider` (excludes generated `.g.dart` files)
- Current rules:
	- Block nullable collection query signatures (`List?/Map?/Set?` for `Ref ref` query providers)
	- Block `loading: () => null`
	- Block `orElse: () => null`

## Recommended Pattern
- Query provider consumers should handle only four states from source async provider: loading/data/empty/error.
- Query provider output itself should be deterministic and defensive (no throw, no accidental null for collections).
