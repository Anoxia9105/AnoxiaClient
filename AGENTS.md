# AGENTS.md

Flutter IM client (package `anoxia`), cross-platform: Android / iOS / Windows / macOS / Linux / Web (JS + Wasm). Active work is on branch `start_web` (web support). Repo docs and code comments are in Chinese; match that style.

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # required after any @riverpod / drift table / go_router change
dart run build_runner watch --delete-conflicting-outputs
dart run tool/check_architecture.dart                       # architecture check: provider layer must not import UI / DioClient
dart run flutter_oss_licenses:generate                      # regenerates lib/oss_licenses.dart
flutter analyze
flutter test
flutter run -d windows / -d chrome / ...
```

- Generated `*.g.dart` files are **committed** (35 files) — after codegen, the diff must include them. Do not edit them by hand.
- `pubspec.lock` is gitignored; never rely on it for dependency state.
- Flutter is on `PATH` (stable); `.fvmrc` exists but no `.fvm/` checkout is installed.

## Web support (critical quirks)

- Native-only plugins (window_manager, tray_manager, desktop_multi_window, hotkey_manager, mobile_scanner, image_cropper, image_gallery_saver_plus, flutter_background, pip) must **never be imported directly** in cross-platform code. Use the conditional-export shims in `lib/platform/shims/*_shim.dart`:
  ```dart
  export 'xxx_stub.dart' if (dart.library.io) 'package:xxx/xxx.dart';
  ```
- Platform detection uses `dart.library.io`, **not** `dart.library.html` (false under Wasm). Same rule applies to the drift database split (`database.dart` → `database_web.dart` / `database_native.dart`; web runs WasmDatabase in a worker — `web/drift_worker.js`, `web/sqlite3.wasm`).
- Hand-written protobuf codec (`lib/framework/codec/proto_reader.dart`, `proto_writer.dart`) must keep varint math in `BigInt` — dart2js bitwise ops are 32-bit and truncate int64 fields (timestamps/seq/senderId). Do not "simplify" back to `<<`/`>>>`. Also avoid int literals > 2^53 in code compiled to web (compile error).
- Web tests: `flutter test --platform chrome` requires `--no-sandbox` (Chrome sandbox). `test/framework/codec/proto_codec_web_test.dart` covers codec edge cases incl. int64.
- `tool_build_web.py` (root) is the supported web build: `pub get` + `flutter build web --release` — conditional imports make this work with the full pubspec. **`tool_import_swap.py` is legacy and hardcodes an absolute path; do not use it.**
- i18n startup locale: easy_localization's device-locale detection is **broken under Wasm** (its internal `intl_standalone.dart if (dart.library.html) intl_browser.dart` conditional falls to the `dart:io` branch when `dart.library.html` is false, `Platform.localeName` throws on web and `Intl.systemLocale` stays `en_US` → UI always English). Startup locale is resolved by `SystemLocale` shim (`lib/platform/shims/system_locale_*.dart`, reads `navigator.language` via `package:web`) and passed as `startLocale` to `EasyLocalization` in `_buildAppWrapper` (saved user choice still wins via `saveLocale`); `DioClient().setLocale` uses the same resolution. Keep both in sync — never rely on easy_localization's device detection.
- In `main.dart`, WASM-safe error handling matters: no `dart:io Platform` access in error paths (`ErrorWidget.builder`, `FlutterError.onError`).

## Architecture

- `lib/main.dart` — entry: `runMainApp()` / `runSubApp()` / `runUpdateApp()`. Desktop sub-windows (call/live) must use an **isolated `ProviderContainer`** that only syncs the auth token (`_createIsolatedWindowContainer`); never share keepAlive chat/call/ws providers across windows.
- `lib/framework/` — codec (protobuf), protocol (WS packets, registered in main via `PacketRegistry`), local_cache (drift + sync repository), network (Dio, TokenManager), provider (all Riverpod), theme, logs (talker).
- `lib/features/<module>/presentation/{pages,widgets}` — UI per feature. `lib/common/` — constants (API base URLs live in `lib/common/constants/api.dart`, production defaults, local URLs commented), utils, shared widgets.
- Provider layer (`lib/framework/provider/`) must not import `common/widgets/`, `features/*/presentation/`, or `DioClient` directly — enforced by `tool/check_architecture.dart`. UI dialogs/pickers belong at the UI call site (pass data/ids into controllers); HTTP goes through `domain/` repositories + `core/*_repository_provider.dart`. Whitelisted bridges: `toast_service_provider.dart` (Toast abstraction), `router.dart` (page composition).
- `code_wiki.md` (root) — detailed architecture/protocol/flow documentation; read it before touching message sync, WS, or call logic.
- Message sync invariants (enforced, do not regress): incremental sync (`sync_repository.dart` `_doSyncMessages`) loops until the backlog is caught up (server caps one batch at pageSize=100) and advances the watermark to the **max seq in the response** — the response is one contiguous SQL range, so holes inside it are permanent server-side gaps (recalled/deleted rows) and skipping past them loses nothing; the WS-push path (`LocalDataSource._advanceMessageWatermark`) still requires continuity (+1); history loads via `lastSeq` + `direction=0` (server has no `before_seq`/`since` params); `syncRoomMessages` records the actual locally-persisted max seq, never the server's latest seq, so a partial batch keeps syncing on the next room entry; conversation merge **reconciles** against the authoritative unpaginated server room list — local rows absent from the response are deleted (with their messages + sync watermark); skip `markAsRead` when a device is already read; offline retry queue is SQLite `SENDING`/`FAILED` rows via `SyncRepository.retryPendingOutgoing()`, not SharedPreferences frames; **in-flight-dedup futures must never have their `whenComplete` callback return the removed map future** (`.remove(key)` returns the very future being awaited → self-wait deadlock); `RemoteDataSource.fetchConversations` returns `null` on a malformed response and callers must not treat `null` as "no rooms" (that would wipe the local cache).

## Conventions

- Provider rules (`lib/framework/provider/core/provider_defensive_contract.md`): query providers return nullable `T?` for single lookups, empty collections for lists/maps (never nullable collections), never throw in query paths, never encode loading as `null`.
- `analysis_options.yaml` enforces: single quotes, `avoid_print` (use talker `log`), `always_declare_return_types`, `avoid_void_async`, `prefer_const_constructors`. File names snake_case, classes PascalCase, providers suffixed `Provider`.
- i18n via easy_localization (`assets/i18n/{zh,en,ja}.json`); use `.tr()`/`.tr(args:)`, never hardcode user-facing strings.
- Commit messages are short Chinese (`优化`, `bug fix`). No CI is configured — `flutter analyze` + `flutter test` locally before committing.
