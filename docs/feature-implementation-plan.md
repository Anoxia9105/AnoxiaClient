# AnoxiaClient 功能实现计划（P0 / P1 / P2 + 工程基建）

> 创建：2026-10-19。本文是后续实现的执行清单：每个任务完成后必须补/跑单测（见「通用验收」）。
> 范围约定：P0 全做、P1 全做、P2 只做「消息表情回应（Reactions）」；工程基建做「测试盲区补强」「反馈附带日志导出」（CI 不在本计划内）。
> 本计划同时覆盖为实现而必须动的 `AnoxiaProtocol` / `AnoxiaServer` 配套改动（P1/P2 跨仓部分会明确标注）。

## 0. 状态总览

| 编号 | 功能 | 仓 | 预估成本 | 状态 |
|------|------|----|---------|------|
| INF-1 | 测试盲区补强 | Client | 中 | ✅ 完成（commit 8965364e，新增 42 个用例） |
| INF-2 | 反馈附带运行日志导出 | Client（+Server 小改） | 中低 | ✅ 完成（client 46cf972b + server f5cc87a5；线上库需执行 `2026-10-19-bug-feedback-diagnostics.sql`） |
| P0-1 | 会话输入草稿持久化 | Client | 低 | ✅ 完成（InputDrafts 表 schema v4 + 500ms debounce store + 控制器恢复/flush/清除，migration/test 套件同步） |
| P0-2 | 单聊双向已读回执 UI | Client（视 P0-2 调研结果） | 低 | ☐ 待做 |
| P0-3 | AI 翻译 + 未读一键总结 | Client | 中低 | ☐ 待做 |
| P0-4 | 聊天媒体时间线（媒体/文件/链接） | Client | 中低 | ☐ 待做 |
| P0-5 | 应用锁（生物识别/PIN） | Client | 中 | ☐ 待做 |
| P1-1 | 消息编辑 | Protocol + Server + Client | 中 | ☐ 待做 |
| P1-2 | 通话记录页 | Server + Client | 中 | ☐ 待做 |
| P1-3 | 会话设置云同步（免打扰/置顶） | Server + Client | 中低 | ☐ 待做 |
| P2-1 | 消息表情回应 Reactions | Protocol + Server + Client | 大 | ☐ 待做 |

不做：桌面聊天多窗口、聊天记录导出/备份（本轮明确排除）。

## 0.1 执行顺序（依赖与风险驱动）

```
批次一（工程基建，先建护栏）
  1. INF-1 测试盲区补强（含重连退避抽纯函数——为后续 ws 改动铺路）
  2. INF-2 反馈附带日志
批次二（P0，纯客户端，按 ROI 逐个落地）
  3. P0-1 草稿  →  4. P0-2 已读回执 UI  →  5. P0-4 媒体时间线
  →  6. P0-3 AI 翻译/总结  →  7. P0-5 应用锁（涉及新依赖，放批尾）
批次三（P1，跨仓：先协议 bump 一次到位）
  8. P1-1 消息编辑（唯一动协议的任务，随批次一起走协议标准流程）
  →  9. P1-3 会话设置云同步 →  10. P1-2 通话记录页
批次四（P2 大协议改动）
  11. P2-1 Reactions
```

## 0.2 通用工程约定（每个任务都要遵守）

- Riverpod 3：新增 Provider 一律 `@riverpod`/`@Riverpod` 注解 + 代码生成；`.g.dart` 与源码同一 commit 提交。
- 改 drift 表 / 路由 / Riverpod 注解后必须 `dart run build_runner build --delete-conflicting-outputs`。
- Provider 层（`lib/framework/provider/`）禁止 import `common/widgets/`、`features/*/presentation/`、`DioClient`；HTTP 走 `domain/` 接口 + `data/repositories/` 实现 + `core/*_repository_provider.dart` 桥接。
- 原生插件不得直接 import 进跨端代码：一律走 `lib/platform/shims/*_shim.dart` 条件导出；平台判断用 `dart.library.io`（禁止 `dart.library.html`）。
- i18n：所有用户可见文案进 `assets/i18n/{zh,en,ja}.json`，用 `.tr()`；提交前跑 `python i18n_check.py`。
- 代码风格：单引号、`avoid_print`（用 talker `log`）、snake_case 文件名、`Provider` 后缀。
- 安全不变量：不得回归 AGENTS.md「消息同步不变量」（连续水印、空洞跳过、幂等、in-flight-dedup 死锁、null 判空等）。
- 每个功能一个 commit，中文短信息（如「聊天输入草稿持久化」）。
- 协议变更标准流程（P1-1/P2-1）：改 `im.proto` → `buf lint` + `buf breaking` → `./tool_generate_dart.ps1` → 客户端跑 `flutter test test/framework/codec/im_packet_v6_test.dart` + `flutter analyze` → 服务端 `mvn test -pl netty -am` → 同步三处版本号（`AnoxiaProtocol/pom.xml`、`gen/dart/pubspec.yaml`、`AnoxiaServer` 根 pom `<anoxia.protocol.version>`）。

## 0.3 前置调研任务（实现批次二前先确认，半天内）

| # | 要确认的事实 | 影响任务 | 核实落点 |
|---|-------------|---------|---------|
| F1 | `chatMembers` 接口 / `ChatRoomMemberVO` 是否已带对端 `readSeq` | P0-2 | `room_member_service.dart`、服务端 `ChatController#getMembers` |
| F2 | talker 能否同步取最近 N 条历史日志（`talker_flutter` history/stream） | INF-2 | ✅ 已解决：talker 实际未接线（`lib/framework/logs/` 只有 debug_log）；改用 drift `sync_logs` 表（发布版可见）+ debug 环形缓冲 `AppRuntimeLog` |
| F3 | `feedback/submit` 是否已支持文件参数（当前只有 images） | INF-2 | ✅ 已解决：`files` 被 `FeedbackImagePolicy` 魔数校验锁死在图片；诊断走新增独立 `diagnostics` 文本字段 + `bug_feedback.diagnostics` 列（`FeedbackDiagnosticsPolicy` 清洗/截断） |
| F4 | 主框架导航结构（desktop 侧栏 / mobile 底栏现有项） | P0-4、P1-2 入口 | `main_layout_page.dart`、`MobileBottomBar.dart` |
| F5 | AI 可用性门控 provider 现名（`ai_feature_flags_provider.dart`） | P0-3 | 直接读取确认 |

---

## 批次一：工程基建

### INF-1 测试盲区补强

目标：给「高危但零测试」的模块补单测，保守目标 15+ 个新 test case。

| 盲区 | 为什么危险 | 测试内容 | 落点 |
|------|-----------|---------|------|
| 重连退避 / Full Jitter | AGENTS.md 明确写它是防后端重启惊群的关键，但没有断言 | `attempt=n` 时 `1 ≤ delay ≤ min(30, 2^n)`；多次调用 [1,base] 区间有随机分布 | 若逻辑内嵌 `ws_controller.dart`，先抽纯函数 `_computeBackoff(attempt, rand)`（不改行为）再测 |
| `chat_input_controller.dart` 发送超时 | 超时算法错误=消息永远转圈或过早失败 | `_resolveSendTimeoutSeconds`：附件数 0/多、audio/file/video 加成、10~30 钳制边界 | `test/framework/provider/chat_input_timeout_test.dart` |
| 计划中的 drift 迁移 | 漏写 schemaVersion/upgrade 老库会整体失效 | 用 `drift_dev` 的 MigrationUtils：先开旧 schema 种数据 → 升级 → 断言数据完好、新表存在 | `test/framework/local_cache/migration_*_test.dart` |
| 输入上限 / 粘贴 | 超长粘贴被静默吞或越限发送 | `ChatInputLimit.canPaste` / `UploadValidator` 边界（空、限长 1、限长+1、含 media 标记的 Delta） | 同上 style，一组参数化用例 |
| typing 节流与去重 | 节流失效会打爆服务端 highFrequency 通道 | fake_async:`_typingTimer/_typingThrottle` 状态机（开始输入→发一次；5s 停止→发 stop；重复输入不重发） | `test/framework/provider/chat_typing_throttle_test.dart` |
| DND × 消息预览组合 | 通知策略直接面向用户 | `message_notification_policy.dart` 已有测试，补「DND 房间对应策略=静默」矩阵用例 | 扩展现有 policy 测试 |

验收：`flutter test` 全绿；不改动任何业务行为（除允许的「抽纯函数」重构）。

### INF-2 反馈附带运行日志导出

- 依赖 F2/F3 结论。
- 客户端：
  - 新 `lib/common/utils/log_export_util.dart`：从 talker 取最近 N 条（默认 200）→ Sanitizer 脱敏（抹 `Authorization: Bearer xxx`、任何 `token=`、邮箱/手机号模式）→ 写入临时目录文本文件；纯函数 `_maskLogLine(String)` 可单测。
  - `settings_feedback_section.dart` 增加「附带运行日志」开关（默认关，i18n 三语），提交时把日志文件参数带上。
  - Web 端 shim 兜底：日志导出仅原生端入口可见（`dart.library.io` 判断），Web 用行为文案「请提供截图」。
- 服务端（小改）：`BugFeedbackController` 接受可选 log 文件字段，走现有多媒体上传通道保存，Size 上限（如 512KB）。`mvn test` 补 controller 策略用例。
- 测试：sanitizer 脱敏用例、导出文件非空/截断用例、settings 开关持久化用例。

---

## 批次二：P0（纯客户端）

### P0-1 会话输入草稿持久化

- 数据层：
  - `tables.dart` 新增表 `InputDrafts`：`roomId`(PK)、`deltaJson`(text)、`plainText`(text)、`updatedAt`(dateTime)；`database.dart` schemaVersion+1，migration 创建表（Web 端 WasmDatabase 同一份 schema，自然生效）。
  - 查询挂到 `LocalDataSource`（遵循现有缓存层风格；`local_data_source_consistency_test.dart` 相应补新表一致性用例）。
- Provider 层：`chat/input/input_draft_store_provider.dart`（`@riverpod` class InputDraftStore）：`load(roomId)`/`save(roomId,delta)`（内部 debounce 500ms 合并写）/`clear(roomId)`。
- 逻辑：
  - `ChatInputController.build(roomId)`：先构造空 controller，再异步读草稿；仅当 controller 仍为空时才 `compose` 草稿（防竞态：用户已提前打字则丢弃恢复）。
  - 编辑器内容变化 → debounce 保存；`ref.onDispose`（切房间）时立即落一次盘。
  - 发送成功路径（现有 clear/clean 全部逻辑处）调用 `clear(roomId)`。
- UI：无新增 UI。
- 测试：切房间保存/恢复（fake_async）、发送后清除、批量快速输入只落一次盘、migration 测试（纳入 INF-1 迁移套件）。

### P0-2 单聊双向已读回执 UI

- 依赖 F1 结论：
  - 若成员接口/房间列表已带对端 `readSeq`：直接用。
  - 若没有：v1 降级方案 = 会话进入/回包刷新时使用服务端房间行里对端已读水位（若也没有，则本任务改为「已送达 ✓」气泡态，并停在此版本，不硬造协议）。
- 逻辑：纯展示层——`user_message_bubble.dart` 增加「已读」标识：条件 `message.seq != null && peerReadSeq >= message.seq && 单聊 && 消息是我发的 && 已 ACK`。
- 数据口径：peerReadSeq 以会话级缓存为准（`room_list_service`/`room_member_service` 提供的一次值 + 房间列表 reconcile 时更新），不做实时推送（避免协议改动，P1-3 云同步顺带提供更好的刷新点）。
- UI 细节：气泡右下小对勾文字态（i18n `chat.read`），遵循减少动效设置；主题 32 色下对比度可用现有 `ColorScheme` 派生色。
- 测试：判定纯函数（seq 边界：等于/小于/空）单测；气泡渲染 widget 测试（按 AGENTS.md 的 easy_localization 测试要求：mock SP、`initEasyLocation`、内层 MaterialApp 挂 `context.localizationDelegates`、自定义同步 AssetLoader、显式 `startLocale`）。

### P0-4 聊天媒体时间线

- 入口（依 F4）：聊天 App 右侧菜单「媒体与链接」+ 群详情页入口；路由 go_router 新 `MediaTimelineRoute`（builder 生成器产物一并提交）。
- 数据：`LocalDataSource` 新增三类查询（按 `conversationId + messageType`）：
  - 媒体：image/video（按 seq 倒序、分页按 `seq < oldestSeq`，遵守仓库「不用 offset」惯例）
  - 文件：file 类型（用 attachment 原始名/大小/时间展示）
  - 链接：text 消息中 URL 提取（复用 `link_preview_card` 的解析口径，抽公共 util）
- UI：三 Tab（媒体九宫格/文件列表/链接列表），点媒体复用 `image_viewer.dart`；空态用 `NoData`；骨架屏沿用 `chat/skeleton` 风格。
- Provider：`chat/media/media_timeline_provider.dart` 按房间 family。
- 测试：查询正确性种子测试（参照 `room_messages_cache_test.dart`）、URL 提取用例、路由回退测试。

### P0-3 AI 翻译 + 未读一键总结

- 前置门控：全部入口先查 F5 的 AI 可用性 flags（现成 `ai_feature_flags_provider.dart`），不可用时不显示。
- 翻译：
  - 消息长按菜单加「翻译」（仅 text/代码消息）；面板内显示译文 + 目标语言 = 当前 UI locale。
  - Provider：`chat/message/ai_message_tools_provider.dart`（按 message family；内存缓存 key=`messageId+targetLang`）；SSE 复用 `framework/network/sse_client.dart` 与 `/chat/ai/stream`（请求体协议照抄 `ai_chat_controller.dart` 现有形态，prompt 客户端组）。
  - 会话切换/登出面销毁：挂进现有 `session_reset_service.dart` 清理清单。
- 未读总结：
  - 进入会话时若 `unreadCount ≥ 20` 在列表顶部显示引导条「AI 总结未读」。
  - 取本地 drift `seq > lastReadSeq` 的消息拼 prompt（去掉媒体只取文本 + 统计），SSE 流式输出到底部弹层；弹层操作：跳到最早未读（复用 `reply_jump_provider` 的定位能力）。
- i18n：`chat.translate`、`chat.ai.summarize_unread`、`chat.ai.summary_sheet_title` 等三语 key。
- 测试：prompt 组装用例（含空文本/媒体-only 房间）、SSE 解析复用用例、AI 不可用时不显示入口的 widget 测试。

### P0-5 应用锁

- 新依赖：`local_auth`（pubspec + `dart run flutter_oss_licenses:generate` 刷新 `lib/oss_licenses.dart`）。
- Shim（关键，防 Web 编译崩）：
  - `lib/platform/shims/biometric_auth_shim.dart`：`export stub if (dart.library.io) real`；真实实现包 `local_auth`，对 Windows 走 `local_auth_windows`（Windows Hello），iOS/Android 走 FaceID/指纹/锁屏密码。
- 状态机（`framework/provider/core/app_lock_controller.dart`，策略纯函数独立以便测试）：
  - 触发：App 进入后台/失焦 ≥ 阈值（设置项：立即 / 1 分钟 / 5 分钟），回前台先盖 `LockPage`。
  - 校验：优先生物识别，失败 3 次或设备无生物能力 → PIN（4-6 位，`flutter_secure_storage` 存储，`SSUtil` 封装）。
  - Web：无生物能力，仅 PIN 模式（默认不引导开启）。
- 设置：`settings/` 新 `settings_security_section.dart`（开启/关闭、改 PIN、阈值选择）。关闭需先通过生物/PIN 校验。
- 测试：策略状态机（后台时间边界、阈值变更即时生效）、shim stub 在 web 编译产物中永远返回「不支持」、LockPage 校验流程（假 authenticator 注入）。

---

## 批次三：P1（跨仓）

### P1-1 消息编辑（唯一动协议任务，随批次走标准流程）

- 协议（AnoxiaProtocol）：
  - `ClientFrame.body` 追加 `EditMessageCommand`（新字段号 15）：`room_id`、`message_id`、`payload`（仅 Text/RichText 两种）。
  - `MessageOperationType` 已有 `EDITED=2`，`MessageOperationEvent.metadata` 携带 `edited_payload_json`（metadata 仅展示/同步，符合「metadata 不触发权限行为」约定）。
  - bump 三处版本号；`buf lint` + `buf breaking`（新 oneof 分支为兼容追加，breaking 应通过）。
- 服务端（AnoxiaServer）：
  - `UpstreamMessageService` 新增编辑分支：校验发送者本人 + 编辑窗口（服务端固定 15 分钟，客户端不重复判定）→ 写 `message_operation`(EDITED + payload 快照) → 房间 Pub/Sub 广播 `MessageOperationEvent(EDITED, metadata.payload_json)`。
  - 历史/同步路径：拉历史时按操作表合并最终 payload（IM-Message-Lifecycle 文档同步更新）。
- 客户端：
  - `im_packet_v6.dart` 新增 `encodeEditFrame`；`ws_controller.dart` operation 分发补 `2=EDITED`（现在只处理 1/3）：更新内存 `chatMessagesProvider` + drift 里 `payloadJson/content/updatedAt`。
  - 上下文菜单：「编辑」仅对我发出的 text/rich 且在窗口内显示；点击进入输入框填充原文本（复用现有 draft/初始化逻辑），发送走编辑命令（非新消息）；气泡展示「已编辑」角标（i18n）。
  - 离线场景：编辑命令失败回落 = 本地不修改（不进离线重试队列，v1 明确不做）。
- 测试：
  - 协议：`ProtocolContractTest`（服务端）加 Edit 分支；客户端 `im_packet_v6_test.dart` 增 encode/decode 用例 + 固定 wire bytes 追加。
  - 客户端：ws 分发 2=EDITED 更新内存/drift 用例；UI「已编辑」角标、超窗不可编辑用例。

### P1-3 会话设置云同步（免打扰/置顶）

- 服务端：
  - SQL 增量文件（根目录惯例命名）：`2026-10-xx-chat-room-member-settings.sql`：`chat_room_member` 加 `is_muted`、`is_pinned` 列。
  - 房间列表接口 VO 带两字段；新 `POST /chat/room/settings`（或并入既有 update 通道，实现时按 controller 既有风格落 `ChatController`）。并发写策略：客户端乐观更新 + 最后写入胜出于服务端持久层即可。
- 客户端：
  - `ChatRoomVO` 增两字段；`pinned_rooms_provider` / `do_not_disturb_rooms_provider` 改造为「服务端为真源 + 本地缓存兜底/乐观回显」：拉列表时 reconcile，切换时先本地生效再异步推送（失败 toast）。
  - 兼容：服务端未升级（旧部署）时字段为空 → 回落现行本地行为（与后端字段的兼容读取写在 repository 层）。
- 测试：reconcile 用例（服务端覆盖本地、缺失字段回退本地）、乐观切换/失败回滚用例。

### P1-2 通话记录页

- 服务端：聚合查询封装（CALL_STARTED/ENDED 系统事件已有的数据），新 REST `GET /call/history?orderBy&pageSize`（PageHelper 分页，规约照 `BaseController` + `startPage()`）；未结束的通话给进行中标记。
- 客户端：
  - domain：`CallLogEntry`；repository（`domain/repositories/+ data/repositories/impl` + provider 桥接）。
  - 路由 `CallHistoryRoute` + 页面；入口依 F4 结果挂主框架（桌面侧栏 / 移动底栏第 N 项），点条目可跳转对应会话。
  - i18n：`call.history`、`call.history.empty` 等。
- 测试：repository 解析（空表/乱序/进行中）用例、页面渲染 + i18n 三语用例、入口跳转路由用例。

---

## 批次四：P2-1 消息表情回应（Reactions）

- 协议：
  - `ClientFrame.body` 追加 `MessageReactionCommand`（新字段号 16）：`room_id`、`message_id`、`emoji`、`is_remove`。
  - `ServerFrame.body` 追加 `ReactionEvent`（新字段号 19）：`room_id`、`message_id`、`sender_user_id`、`emoji`、`is_remove`、`server_timestamp_ms`。
  - 版本三处 bump + 标准校验流程。
- 服务端：
  - 新表 `chat_message_reaction(message_id, emoji, user_id, created_at)` SQL 增量文件；逻辑：本人单消息单 emoji 只留一条（幂等）；广播 `ReactionEvent`（不占消息 seq——不进同步 backlog，重新进房时走 REST 拉）。
  - REST：`GET /chat/reactions?roomId=...`（按房间批量取，供进房补拉）。
- 客户端：
  - `ws_controller` 新 `reactionEvent` 分发 → `chatMessagesProvider` 内聚合（每 message 维护 `Map<emoji, {count, mine}>`）；drift 新表或消息 propertiesJson 扩展（实现时按一致性测试最小改动选择，倾向独立表）。
  - 进房补拉：`sync_repository` 房间进入流程附加重放 reactions。
  - UI：长按菜单表情行（预置 6-8 个 emoji）；气泡下缘聚合条（我方已表态高亮）；再次点按同 emoji = 取消。
- 测试：协议契约与 wire 用例、ws 分发聚合用例、幂等（重复点击不重复计数）、reconcile（REST 事件覆盖内存）用例。

---

## 发布与回归门禁（每批次结束统一跑）

```bash
flutter analyze
flutter test
flutter test test/framework/codec/im_packet_v6_test.dart   # 协议批次必须
python i18n_check.py
# 有协议改动时：
../AnoxiaProtocol/tool_generate_dart.ps1                    # 生成后 build_runner
# 服务端批次：
mvn test -pl netty -am   # 以及对应 admin test
```

每批次完成后同步更新 `README.md` 功能一览与 `code_wiki.md` 对应章节（保持 Chinese 文风）。

## 风险与回滚

| 风险 | 缓解 |
|------|------|
| P0-2 对端 readSeq 可能拿不到 | 调研 F1 前置；降级方案「已送达 ✓」，不做协议外硬造 |
| drift schema 升级破坏老用户库 | INF-1 先建 migration 测试套件，P0-1 首个消费 |
| 协议 bump 三处不同步 | 每个 P1/P2 任务显式 checklist + `buf breaking` 拦截 |
| local_auth 桌面体验差异 | P0-5 放批尾；Web/能力不足端只提供 PIN |
| AI prompt 长度/费用 | 总结入口设未读阈值与单次上限（如近 100 条），明确提示 |
