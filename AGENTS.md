# AGENTS.md

Flutter IM client (package `anoxia`), cross-platform: Android / iOS / Windows / macOS / Linux / Web (JS + Wasm). 分支策略：本地与远程只保留 `master`，Web/桌面/移动端全部在 master 上开发。Repo docs and code comments are in Chinese; match that style.

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # required after any @riverpod / drift table / go_router change
dart run build_runner watch --delete-conflicting-outputs
dart run flutter_oss_licenses:generate                      # regenerates lib/oss_licenses.dart
flutter analyze
flutter test
flutter test test/framework/codec/im_packet_v6_test.dart    # 改协议或升级 proto 后必跑（固定 wire bytes 回归）
flutter run -d windows / -d chrome / ...
```

发布构建走根目录脚本（内含「生成 Dart 协议 → pub get → wire 测试 → build」四步，缺一不可）：

```powershell
./tool_build.ps1 -Target web            # ./tool_build.ps1 | .bat | .sh 三平台入口都在根目录
./tool_build.ps1 -Target web -Wasm
./tool_build.ps1 -Target android        # 内部映射为 flutter build apk
./tool_build.ps1 -Target windows -Debug
```

- Generated `*.g.dart` files are **committed** (目前 40+ 个) — after codegen, the diff must include them. Do not edit them by hand.
- `pubspec.lock` is gitignored; never rely on it for dependency state.
- Flutter is on `PATH` (stable); `.fvmrc` exists but no `.fvm/` checkout is installed.
- There is **no `tool/` directory** — the old `dart run tool/check_architecture.dart` architecture gate has been deleted; the layering rules below are now convention-only and enforced in review. `tool_import_swap.py` no longer exists either (historical, do not resurrect).
- 字体：`pubspec.yaml` 声明 JetBrainsMono + NotoSansSC 两套族并全平台强制使用（含 Web，不回退系统字体），测试环境同样按真实排版运行；新增 UI 不要假设等宽之外的默认字体。easy_localization 在测试环境需手动 `SharedPreferences.setMockInitialValues` + `EasyLocalizationController.initEasyLocation()`，并显式传 `startLocale`（设备 locale 会解析到不存在的 `zh-CN.json`）。

## Web support (critical quirks)

- Native-only plugins (window_manager, tray_manager, desktop_multi_window, hotkey_manager, mobile_scanner, image_cropper, image_gallery_saver_plus, flutter_background, pip) must **never be imported directly** in cross-platform code. Use the conditional-export shims in `lib/platform/shims/*_shim.dart`:
  ```dart
  export 'xxx_stub.dart' if (dart.library.io) 'package:xxx/xxx.dart';
  ```
- Platform detection uses `dart.library.io`, **not** `dart.library.html` (false under Wasm). Same rule applies to the drift database split (`database.dart` → `database_web.dart` / `database_native.dart`; web runs WasmDatabase in a worker — `web/drift_worker.js`, `web/sqlite3.wasm`).
- **V6 协议编解码已切换到生成代码**：WebSocket 二进制负载直接是 `ClientFrame`/`ServerFrame` protobuf（无应用层帧头）。编码/解码统一走 `lib/framework/codec/v6/im_packet_v6.dart`（`ImPacketV6`），底层是 `AnoxiaProtocol` 生成的 Dart 包 `package:anoxia_protocol`（公开 `v6` 命名空间）。**不存在**手写 `proto_reader.dart`/`proto_writer.dart` 或 `PacketRegistry`；V5 相关代码与服务端 `codec/v5` 均已删除（历史文档中“空目录残留”的说法已过期），勿新建 V5 相关代码。生成代码来自相邻仓库 `../AnoxiaProtocol/gen/dart`，未入库，需先运行 `../AnoxiaProtocol/tool_generate_dart.ps1`。固定字段号仅用于独立 wire fixture 回归测试，不得用于业务编解码。下行共 9 种 `ServerFrame`（含 `announcement_event`，仅通知、 `id`+`revision`+`action`，正文走 REST `/system/announcements` 重取）。
- Web tests: `flutter test --platform chrome` requires `--no-sandbox` (Chrome sandbox).
- 上面的构建脚本每次都会先生成协议；**直接手敲 `flutter build` / `flutter test` 时也必须自己先跑 `../AnoxiaProtocol/tool_generate_dart.ps1`** —— `pub get` 不会刷新 path 依赖。不要为客户端刷新去跑双语言 `buf generate`（它会改写 Java lite 产物）。
- i18n startup locale: easy_localization's device-locale detection is **broken under Wasm** (its internal `intl_standalone.dart if (dart.library.html) intl_browser.dart` conditional falls to the `dart:io` branch when `dart.library.html` is false, `Platform.localeName` throws on web and `Intl.systemLocale` stays `en_US` → UI always English). Startup locale is resolved by `SystemLocale` shim (`lib/platform/shims/system_locale_*.dart`, reads `navigator.language` via `package:web`) and passed as `startLocale` to `EasyLocalization` in `_buildAppWrapper` (saved user choice still wins via `saveLocale`); `DioClient().setLocale` uses the same resolution. Keep both in sync — never rely on easy_localization's device detection.
- In `main.dart`, WASM-safe error handling matters: no `dart:io Platform` access in error paths (`ErrorWidget.builder`, `FlutterError.onError`).

## Architecture

- `lib/main.dart` — entry: `runMainApp()` / `runSubApp()` / `runUpdateApp()`. Desktop sub-windows (call) must use an **isolated `ProviderContainer`** that only syncs the auth token (`_createIsolatedWindowContainer`); never share keepAlive chat/call/ws providers across windows.
- `lib/` 顶层六块：`framework/`（基础设施）、`domain/`（repository 接口 + usecase）、`data/`（`*_repository_impl.dart` 实现）、`features/`（页面）、`common/`（跨模块工具与共享 widget）、`App.dart`。
- `lib/framework/` — codec (V6 protobuf via `ImPacketV6` + `anoxia_protocol`), protocol (V6 domain models/IPacket), local_cache (drift + sync repository), network (Dio, TokenManager, `sse_client.dart`), core (push/toast/notification + web/native 拆分), provider (all Riverpod), theme, logs (talker), extensions. WS 收发与 ACK/重连/幂等都在 `lib/framework/provider/ws/ws_controller.dart`。
- Provider 子目录按域划分：auth / chat（input、message、room、call、favorite）/ contact / note / ai / announcement / layout / desktop / theme / ws / core / router。新增能力优先落在对应域目录，不要往根目录堆文件。
- `lib/features/<module>/presentation/{pages,widgets}` — UI per feature。现有模块：`app`（登录/注册/扫码登录/主框架）、`chat`（会话、群、通话、输入场、消息气泡）、`contact`、`favorite`（收藏）、`note`（记事本）、`me`、`settings`、`update`、`announcement`（只有 `presentation/widgets/`）。
- `lib/common/` — constants (API base URLs live in `lib/common/constants/api.dart`, production defaults, local URLs commented; `storage_keys.dart`, `call_window_sizes.dart`), utils (`device_util.dart`, `file_util.dart`, …), shared widgets (`app/`, `desktop/`, `dialogs/`)。
- Provider layer (`lib/framework/provider/`) must not import `common/widgets/`, `features/*/presentation/`, or `DioClient` directly — this was once checked by `tool/check_architecture.dart`, but that script has been removed, so **keep the rule in code review**. UI dialogs/pickers belong at the UI call site (pass data/ids into controllers); HTTP goes through `domain/` repositories (impl 在 `data/repositories/`) + `core/*_repository_provider.dart`. Whitelisted bridges: `toast_service_provider.dart` (Toast abstraction), `router.dart` (page composition).
- `code_wiki.md` (root) — detailed architecture/protocol/flow documentation; read it before touching message sync, WS, or call logic.
- Message sync invariants (enforced, do not regress): incremental sync (`sync_repository.dart` `_doSyncMessages`) loops until the backlog is caught up (server caps one batch at pageSize=100) and advances the watermark to the **max seq in the response** — the response is one contiguous SQL range, so holes inside it are permanent server-side gaps (recalled/deleted rows) and skipping past them loses nothing; the WS-push path (`LocalDataSource._advanceMessageWatermark`) still requires continuity (+1); history loads via `lastSeq` + `direction=0` (server has no `before_seq`/`since` params); `syncRoomMessages` records the actual locally-persisted max seq, never the server's latest seq, so a partial batch keeps syncing on the next room entry; conversation merge **reconciles** against the authoritative unpaginated server room list — local rows absent from the response are deleted (with their messages + sync watermark); skip `markAsRead` when a device is already read; offline retry queue is SQLite `SENDING`/`FAILED` rows via `SyncRepository.retryPendingOutgoing()`, not SharedPreferences frames; **in-flight-dedup futures must never have their `whenComplete` callback return the removed map future** (`.remove(key)` returns the very future being awaited → self-wait deadlock); `RemoteDataSource.fetchConversations` returns `null` on a malformed response and callers must not treat `null` as "no rooms" (that would wipe the local cache).

## 技术栈事实（改动前必知）

- Riverpod **3**（`flutter_riverpod ^3.0.3` + `riverpod_annotation ^4` + `riverpod_generator ^4`）：新增 Provider 用注解 + 代码生成，`.g.dart` 必须一起提交。
- 路由 go_router **^17** + `go_router_builder`，产物 `lib/framework/provider/router/router.g.dart`；改路由后必须 `build_runner`。
- 本地库 drift `^2.34`（sqlite3_flutter_libs + Web worker），token/凭据走 `flutter_secure_storage`（`lib/framework/network/token_manager.dart`）；**没有 encrypt/crypto 依赖，不存在端到端加密**，别臆造 E2EE 逻辑。
- V6 协议 Dart 包是 path 依赖 `../AnoxiaProtocol/gen/dart`；`flutter pub get` 不会帮你刷新它，改 proto → 先跑 `../AnoxiaProtocol/tool_generate_dart.ps1`。
- 其他重要依赖：LiveKit + flutter_webrtc（通话）、JPush + firebase_messaging（推送）、flutter_quill（富文本/笔记）、flutter_map（位置消息）、easy_localization（i18n）。
- 测试覆盖很薄，全仓只有 5 个 `*_test.dart`（`test/framework/codec/im_packet_v6_test.dart`、`announcement_dialog_theme_test.dart`、`remote_quality_estimator_test.dart`、`mobile_bottom_bar_slider_test.dart`、`sp_layout_switch_test.dart`；无 `flutter_test_config.dart`）。改动核心链路时优先补单测。

## Conventions

- Provider rules (`lib/framework/provider/core/provider_defensive_contract.md`): query providers return nullable `T?` for single lookups, empty collections for lists/maps (never nullable collections), never throw in query paths, never encode loading as `null`.
- `analysis_options.yaml` enforces: single quotes, `avoid_print` (use talker `log`), `always_declare_return_types`, `avoid_void_async`, `prefer_const_constructors`. File names snake_case, classes PascalCase, providers suffixed `Provider`.
- i18n via easy_localization (`assets/i18n/{zh,en,ja}.json`); use `.tr()`/`.tr(args:)`, never hardcode user-facing strings.
- Small-device handling: main-layout screens are blocked when `DeviceUtil.isScreenTooSmall` (width < 320 || height < 240) and show `UnsupportedDevicePage` (branded notice + optional "continue anyway" for web/desktop). Never raise the height threshold above 240 — it would false-positive on landscape phones (e.g. iPhone SE landscape is exactly 320 tall). Screen width/height thresholds are centralized in `DeviceUtil`; do not inline magic numbers.
- QR 内容约定：二维码必须编码 **URL**（个人名片 `https://chat.anoxia.cn/u/{userId}`，`API.qrUserBaseUrl`），禁止直接编码 JSON——微信等外部扫码器会把 JSON 当纯文本显示。扫码端（`scan_qr_page.dart`）同时兼容 `/u/{userId}` URL 与旧版 `user_card` JSON；URL 名片只有 userId，需经 `contactRepositoryProvider.getContactDetail` 拉详情后直接弹 `AddFriendDialog`。
- Commit messages are short Chinese (`优化`, `bug fix`). No CI is configured — `flutter analyze` + `flutter test` locally before committing.
