# AGENTS.md

Flutter IM client (package `anoxia`), cross-platform: Android / iOS / Windows / macOS / Linux / Web (JS + Wasm). 分支策略：本地与远程只保留 `master`，Web/桌面/移动端全部在 master 上开发。Repo docs and code comments are in Chinese; match that style.

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
- Widget 测试字体：`test/flutter_test_config.dart` 全局加载真实字体（JetBrainsMono + NotoSansSC），所有 golden / 文本断言均按真实排版运行；新增需要视觉验证的页面可参照 `test/features/chat/presentation/widgets/official_room_home_view_preview_test.dart` 的假 Provider + `--update-goldens` 预览模式（截图落到 `build/` 下，非回归断言）。easy_localization 在测试环境需手动 `SharedPreferences.setMockInitialValues` + `EasyLocalizationController.initEasyLocation()`，并显式传 `startLocale`（设备 locale 会解析到不存在的 `zh-CN.json`）。
- Widget 测试字体：`test/flutter_test_config.dart` 全局加载真实字体（JetBrainsMono + NotoSansSC），所有 golden / 文本断言均按真实排版运行；新增需要视觉验证的页面可参照 `test/features/chat/presentation/widgets/official_room_home_view_preview_test.dart` 的假 Provider + `--update-goldens` 预览模式（截图落到 `build/` 下，非回归断言）。easy_localization 在测试环境需手动 `SharedPreferences.setMockInitialValues` + `EasyLocalizationController.initEasyLocation()`，并显式传 `startLocale`（设备 locale 会解析到不存在的 `zh-CN.json`）。

## Web support (critical quirks)

- Native-only plugins (window_manager, tray_manager, desktop_multi_window, hotkey_manager, mobile_scanner, image_cropper, image_gallery_saver_plus, flutter_background, pip) must **never be imported directly** in cross-platform code. Use the conditional-export shims in `lib/platform/shims/*_shim.dart`:
  ```dart
  export 'xxx_stub.dart' if (dart.library.io) 'package:xxx/xxx.dart';
  ```
- Platform detection uses `dart.library.io`, **not** `dart.library.html` (false under Wasm). Same rule applies to the drift database split (`database.dart` → `database_web.dart` / `database_native.dart`; web runs WasmDatabase in a worker — `web/drift_worker.js`, `web/sqlite3.wasm`).
- **V6 协议编解码已切换到生成代码**：WebSocket 二进制负载直接是 `ClientFrame`/`ServerFrame` protobuf（无应用层帧头）。编码/解码统一走 `lib/framework/codec/v6/im_packet_v6.dart`（`ImPacketV6`），底层是 `AnoxiaProtocol` 生成的 Dart 包 `package:anoxia_protocol`（公开 `v6` 命名空间）。**不存在**手写 `proto_reader.dart`/`proto_writer.dart` 或 `PacketRegistry`；`lib/framework/codec/v5/` / 服务端 `codec/v5` 均为空目录历史残留，勿新建 V5 相关代码。生成代码来自相邻仓库 `../AnoxiaProtocol/gen/dart`，未入库，需先运行 `../AnoxiaProtocol/tool_generate_dart.ps1`。固定字段号仅用于独立 wire fixture 回归测试，不得用于业务编解码。
- Web tests: `flutter test --platform chrome` requires `--no-sandbox` (Chrome sandbox). <!--- `test/framework/codec/proto_codec_web_test.dart`（手写 codec 时代遗留，已随 V5 下线）过期，勿依赖 -->
- Windows 构建入口为 `tool_build.ps1` / `tool_build.bat`（Web Wasm：`./tool_build.bat -Target web -Wasm`）：先运行 `../AnoxiaProtocol/tool_generate_dart.ps1` 仅生成 Dart，再 `pub get`、固定 wire bytes 协议测试和 Flutter build。直接运行 Flutter 命令前也必须先生成协议，`pub get` 不会刷新 path 依赖。不要为客户端刷新运行会改写 Java lite 的双语言 `buf generate`。**`tool_import_swap.py` 是历史脚本，禁止使用。**
- i18n startup locale: easy_localization's device-locale detection is **broken under Wasm** (its internal `intl_standalone.dart if (dart.library.html) intl_browser.dart` conditional falls to the `dart:io` branch when `dart.library.html` is false, `Platform.localeName` throws on web and `Intl.systemLocale` stays `en_US` → UI always English). Startup locale is resolved by `SystemLocale` shim (`lib/platform/shims/system_locale_*.dart`, reads `navigator.language` via `package:web`) and passed as `startLocale` to `EasyLocalization` in `_buildAppWrapper` (saved user choice still wins via `saveLocale`); `DioClient().setLocale` uses the same resolution. Keep both in sync — never rely on easy_localization's device detection.
- In `main.dart`, WASM-safe error handling matters: no `dart:io Platform` access in error paths (`ErrorWidget.builder`, `FlutterError.onError`).

## Architecture

- `lib/main.dart` — entry: `runMainApp()` / `runSubApp()` / `runUpdateApp()`. Desktop sub-windows (call) must use an **isolated `ProviderContainer`** that only syncs the auth token (`_createIsolatedWindowContainer`); never share keepAlive chat/call/ws providers across windows.
- `lib/framework/` — codec (V6 protobuf via `ImPacketV6` + `anoxia_protocol`), protocol (V6 domain models/IPacket), local_cache (drift + sync repository), network (Dio, TokenManager), provider (all Riverpod), theme, logs (talker). WS 收发与 ACK/重连/幂等都在 `lib/framework/provider/ws/ws_controller.dart`。
- `lib/features/<module>/presentation/{pages,widgets}` — UI per feature. `lib/common/` — constants (API base URLs live in `lib/common/constants/api.dart`, production defaults, local URLs commented), utils, shared widgets.
- Provider layer (`lib/framework/provider/`) must not import `common/widgets/`, `features/*/presentation/`, or `DioClient` directly — enforced by `tool/check_architecture.dart`. UI dialogs/pickers belong at the UI call site (pass data/ids into controllers); HTTP goes through `domain/` repositories + `core/*_repository_provider.dart`. Whitelisted bridges: `toast_service_provider.dart` (Toast abstraction), `router.dart` (page composition).
- `code_wiki.md` (root) — detailed architecture/protocol/flow documentation; read it before touching message sync, WS, or call logic.
- Message sync invariants (enforced, do not regress): incremental sync (`sync_repository.dart` `_doSyncMessages`) loops until the backlog is caught up (server caps one batch at pageSize=100) and advances the watermark to the **max seq in the response** — the response is one contiguous SQL range, so holes inside it are permanent server-side gaps (recalled/deleted rows) and skipping past them loses nothing; the WS-push path (`LocalDataSource._advanceMessageWatermark`) still requires continuity (+1); history loads via `lastSeq` + `direction=0` (server has no `before_seq`/`since` params); `syncRoomMessages` records the actual locally-persisted max seq, never the server's latest seq, so a partial batch keeps syncing on the next room entry; conversation merge **reconciles** against the authoritative unpaginated server room list — local rows absent from the response are deleted (with their messages + sync watermark); skip `markAsRead` when a device is already read; offline retry queue is SQLite `SENDING`/`FAILED` rows via `SyncRepository.retryPendingOutgoing()`, not SharedPreferences frames; **in-flight-dedup futures must never have their `whenComplete` callback return the removed map future** (`.remove(key)` returns the very future being awaited → self-wait deadlock); `RemoteDataSource.fetchConversations` returns `null` on a malformed response and callers must not treat `null` as "no rooms" (that would wipe the local cache).

## Conventions

- Provider rules (`lib/framework/provider/core/provider_defensive_contract.md`): query providers return nullable `T?` for single lookups, empty collections for lists/maps (never nullable collections), never throw in query paths, never encode loading as `null`.
- `analysis_options.yaml` enforces: single quotes, `avoid_print` (use talker `log`), `always_declare_return_types`, `avoid_void_async`, `prefer_const_constructors`. File names snake_case, classes PascalCase, providers suffixed `Provider`.
- i18n via easy_localization (`assets/i18n/{zh,en,ja}.json`); use `.tr()`/`.tr(args:)`, never hardcode user-facing strings.
- Small-device handling: main-layout screens are blocked when `DeviceUtil.isScreenTooSmall` (width < 320 || height < 240) and show `UnsupportedDevicePage` (branded notice + optional "continue anyway" for web/desktop). Never raise the height threshold above 240 — it would false-positive on landscape phones (e.g. iPhone SE landscape is exactly 320 tall). Screen width/height thresholds are centralized in `DeviceUtil`; do not inline magic numbers.
- QR 内容约定：二维码必须编码 **URL**（个人名片 `https://chat.anoxia.cn/u/{userId}`，`API.qrUserBaseUrl`），禁止直接编码 JSON——微信等外部扫码器会把 JSON 当纯文本显示。扫码端（`scan_qr_page.dart`）同时兼容 `/u/{userId}` URL 与旧版 `user_card` JSON；URL 名片只有 userId，需经 `contactRepositoryProvider.getContactDetail` 拉详情后直接弹 `AddFriendDialog`。
- Commit messages are short Chinese (`优化`, `bug fix`). No CI is configured — `flutter analyze` + `flutter test` locally before committing.
