# 聊天媒体消息：上传反馈 & 类型动态识别 改造方案

> 范围：`AnoxiaClient`（Flutter，Android / iOS / Windows / macOS / Linux / Web）
> 结论：两个问题同源 —— 手机端「媒体消息」这条链路是**先上传、后插入**，且**只识别视频、不识别图片**。

---

## 一、问题 1：手机端发送文件/图片没有任何即时反馈

### 1.1 现状链路（手机端）

```
mobile_chat_input.dart:169  _pickAndSend
  └─ chat_input_controller.dart:580  sendPickedImages   ← await 整条上传
  └─ chat_input_controller.dart:642  sendPickedFiles    ← await 整条上传
        └─ chat_image_upload_controller.dart:173  uploadImages
        └─ chat_file_upload_controller.dart:119   uploadFiles
              └─ 上传全部完成后才 chat_input_controller.dart:1043 _doSend() → 气泡出现
```

### 1.2 根因

1. **先传后插（upload-then-insert）**
   `_doSend` 被放在 `await uploader.uploadImages(...)`（`:613`）/ `await uploader.uploadFiles(...)`（`:676`）**之后**，
   于是"气泡出现时刻 = 整条上传完成时刻"。
   对照 `sendVoiceMessage`（`:815-896`）：先 `upsertMessage` 插一条 `DeliveryStatus.sending` 的本地消息，再后台上传，最后才发帧。
   **项目里已经有正确范式，只是图片/文件/视频没走。**

2. **整个中间态零 UI**
   `MobileChatInput` 没有订阅 `chatImageUploadControllerProvider` / `chatFileUploadControllerProvider`；
   `_pickAndSend` 里 `_closeAllPanels()`（`mobile_chat_input.dart:186`）还在 `await` 之后才执行 —— 上传期间面板仍开着，也没有 toast / 进度。

3. **上传本身不短**（叠加放大感知延迟）
   - `_readImageSizeFromFile` / `_readImageSizeFromBytes`（`chat_input_controller.dart:973`/`:988`）为拿宽高把**整个文件读进内存 + `instantiateImageCodec` 完整解码首帧**，多图**串行 await**；
   - `UploadRepositoryImpl._maxConcurrentUploads = 2`（`upload_repository_impl.dart:14`）→ 多文件排队；
   - 失败重试 3 次 + 400/800ms 退避（`chat_image_upload_controller.dart:266`、`chat_file_upload_controller.dart:219`）。

### 1.3 目标交互

选完 → 面板**立刻**收起 → 气泡**立刻**出现在列表（本地预览 + 进度环 + 百分比）→ 上传完成后气泡**原地**换成服务器资源并发出 → ACK 后转"已发送"；失败 → 气泡进入失败态、点击可重传。

### 1.4 实施方案

**Step 1 · `_doSend` 支持外部传入 `clientMsgId`**（`chat_input_controller.dart:1043`）

```dart
void _doSend({
  required MessageType type,
  required MessagePayload payload,
  List<Attachment>? attachments,
  bool clearReplyAfterSend = true,
  String? clientMsgId,               // 新增：乐观插入与真实发送复用同一 id
}) {
  final String id = clientMsgId ?? const Uuid().v4();
  ...
}
```

与 `sendVoiceMessage`（`:822` 生成 id → `:877 _doSendVoice(clientMsgId: ...)`）保持同一模式。

**Step 2 · 新增"即时发送"入口，替换 `sendPickedImages` / `sendPickedFiles`**

```dart
Future<void> sendPickedAttachments(List<PlatformFile> files) async {
  // 1) 逐文件分类（见第二部分 media_kind_resolver）
  // 2) 逐文件：
  //      clientMsgId = uuid；attachment.id = clientMsgId；attachment.url = 本地路径
  //      先 upsert 本地消息（deliveryStatus: DeliveryStatus.sending）→ 气泡立刻出现
  //      unawaited(upload(..., clientFileIds: [clientMsgId], onProgress: ...))
  // 3) 单文件上传成功 → 用真实 url/width/height 重建 payload → _doSend(clientMsgId: 同一个)
  //    单文件上传失败 → upsertMessage(重建消息.copyWith(deliveryStatus: failed))
}
```

关键约定：**`attachment.id == clientMsgId == clientFileId`**。
这样气泡只要拿到 `clientMsgId` 就能从上传控制器里 `select` 到进度和本地 `bytes`，不需要额外映射表。

**Step 3 · 乐观消息不得入库（重要）**

`ChatMessages.upsertMessage`（`room_message_service.dart:350`）会调用 `cacheLocalMessage` 落 drift；
而 `WsController._resendCachedOutbounds`（`ws_controller.dart:597`）在 WS 重连时会把 drift 里 `SENDING` 的行**原样重放**。
若 payload 里是 `/data/user/0/.../IMG_20260915.jpg`，就会把**本地路径当 URL 发给服务端**。
（这个隐患现在已存在于语音消息链路：`sendVoiceMessage` 上传前就把 `filePath` 写进了 payload。）

守卫（`upsertMessage` 落库前 + `pendingOutgoingMessages()` 双保险）：

```dart
final hasLocalMedia = msg.payload?.mediaAttachments
        .any((a) => a.url != null && a.url!.isNotEmpty && !a.url!.startsWith('http')) ??
    false;
if (!hasLocalMedia) { /* 才 cacheLocalMessage */ }
```

乐观气泡只活在 `optimisticRoomMessagesProvider`（内存）；上传拿到 http url 后走 `_doSend` 才真正入库。
应用被杀 → 气泡消失（正确：上传也没了）；失败态保气泡，重试时重新上传本地文件。

**Step 4 · 气泡进度 UI**

渲染层按 `attachment.id` 取进度（两个控制器都要查，图片走图片控制器、文件/视频走文件控制器）：

```dart
final entry = ref.watch(chatImageUploadControllerProvider.select((m) => m[id]))
           ?? ref.watch(chatFileUploadControllerProvider.select((m) => m[id]));
```

- 上传中：半透明遮罩 + 确定性进度环 + `chat_upload_progress`（i18n 已有：`zh.json:1349`）
- 失败：遮罩 + `upload_failed` / `upload_failed_retry`（`zh.json:640-641`），整块可点触发重传
- 成功：不做特殊标记（气泡已被真实消息替换）

样式直接复用现有编辑器 embed 的进度视觉（`quill_image_build.dart:73-158`：52px 圆底 + 3px 进度环 + 百分比文字 + 底部进度条），保证输入框与气泡观感一致。

**Step 5 · 本地预览 + 尺寸读取优化**

- 新增 `lib/common/widgets/attachment_image_view.dart`，把 `QuillImageBuild._buildEmbeddedImage`（`quill_image_build.dart:174-205`）的逻辑抽成共用组件：
  `http(s)` → 缓存网络图；非 Web 且非 http → `Image.file`；Web → `Image.memory(bytes)`。
  图片气泡与编辑器 embed 共用一份实现（现在气泡写死走 `CachedNetworkImageView`，`image_message_strategy.dart:334`，本地路径必然走 errorWidget）。
- `chat_file_upload_controller` 补一个 `bytesOf(id)`（图片控制器已有：`chat_image_upload_controller.dart:318`）。
- 宽高读取改成**只读文件头**，不解整帧：

```dart
final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
final descriptor = await ui.ImageDescriptor.encoded(buffer);
final size = (descriptor.width, descriptor.height);
buffer.dispose();
descriptor.dispose();
```

  （4 处重复实现：`chat_input_controller.dart:973/988`、`chat_image_upload_controller.dart:330/344`，建议一并收敛。）

### 1.5 必须一起处理的坑

| 风险 | 说明 | 处理 |
|---|---|---|
| **`retain` 误杀即时上传** | `_pruneDeletedUploads`（`chat_input_controller.dart:222`）每次 Quill 文档变化都调 `retain(编辑器里的附件 id)`；而 `retain`（`chat_image_upload_controller.dart:300`、`chat_file_upload_controller.dart:256`）语义是"不在集合里就 `cancelUpload` + 删除"。手机端文档里没有附件 id，**一旦文档变化触发，在飞的即时上传会被全量取消**。现在没爆只是因为手机端不写 Quill 文档。 | 控制器内部记录 `_editorOwnedIds`，`retain` 只清理"编辑器来源"的 id；或即时发送用独立 id 前缀命名空间。顺带修掉 `chat_input_controller.dart:220-221` 那条与实现不符的注释。 |
| **失败重试不会重传文件** | `MessageResender.resend`（`message_resender.dart:27`）只重发 WS 帧，不管附件。失败态若 url 还是本地路径，重发前必须先重新上传。 | 失败态点击重试时，先走 Step 2 的上传分支，成功后再发帧；url 已是 http 的失败消息才走后者的纯重发。 |
| **Hero / 大图查看** | `image_message_strategy.dart:40` 的 heroTag 基于 messageId；本地路径期间点开大图会走网络加载。 | `url` 非 http 时禁用大图详情入口（或走本地文件预览）。 |
| **文件卡片下载按钮** | `file_message_widgets.dart:224` 用 `file.url` 下载/`launchUrl`。 | url 非 http 时禁用下载入口，只显示进度。 |
| **视频未覆盖** | 手机端选视频同样"先传后插"。 | 一并纳入 `sendPickedAttachments`，否则只修了图片和文件。 |
| **上传无超时/取消** | 现在只有 WS ACK 超时（`_resolveSendTimeoutSeconds`，`:66`），上传本身没有上限。 | 给上传加总时长上限或"取消"入口（`cancelUpload` 已具备）。 |

---

## 二、问题 2：所有端"发送文件时如果是图片，应走图片消息"

### 2.1 现状判定矩阵

| 入口 | 平台 | 选中的是图片时 | 现在的结果 |
|---|---|---|---|
| 更多面板「图片」`FileType.image` | 手机真机 | — | `_pickCropAndSendImagesMobile` → `sendPickedImages` → `MessageType.image` ✅ |
| 更多面板「图片」 | Web / 桌面 | — | `sendPickedImages` → `MessageType.image` ✅ |
| 更多面板「文件」`FileType.any` | **手机** | 是 | `sendPickedFiles`：只判视频 → `kind=FILE` → `MessageType.file` ❌ 渲染成**文件卡片** |
| 工具栏「文件」`FileType.any` | Web / 桌面 | 是 | `selectFiles` 插 `file` embed、`kind=FILE`；发送时 `Attachment.isImage` 靠 mime 兜底被算进 `processor.images` → 发出 `MessageType.image`，但有三处不自洽 ⚠️ |

### 2.2 根因

1. **只有视频识别，没有图片识别**
   `_isVideoExtension` 在两处重复（`chat_input_controller.dart:736`、`chat_file_upload_controller.dart:337`），
   `sendPickedFiles` 的分组只有 `isVideo` / `!isVideo`（`chat_input_controller.dart:687-688`）→ **图片必然落进 `fileList`** → `MessageType.file`。
2. **渲染 100% 由 `messageType` 决定**
   `message_render_factory.dart:24-35` 是 `MessageType → Strategy` 的直查表，类型错了就是文件卡片，**对端同样如此**（对端也按 messageType 渲染）。所以必须在**发送侧**就把类型定对。
3. **桌面端"歪打正着"，但留下三处不一致**
   - 编辑器里插的是 `file` embed（`chat_file_upload_controller.dart:103`）→ 显示成文件 chip，不是图片预览；
   - `kind` 仍是 `FILE`，与 `MessageType.image` 不自洽（服务端/对端按 kind 处理时会出现分歧）；
   - `_sendMessageInternal` 的图片分支从**图片控制器**取结果（`chat_input_controller.dart:362`），而这张图是**文件控制器**上传的 → `uploadResultOf` 返回 `null` → `width/height` 丢失，气泡首帧无尺寸、会跳版。

### 2.3 方案：一个分类器 + 一个入口

新增 `lib/common/utils/media_kind_resolver.dart`：

```dart
enum PickedMediaKind { image, video, file }

PickedMediaKind resolvePickedMediaKind({
  String? name,
  String? extension,
  String? declaredType,
}) {
  final mime = mediaMimeTypeForName(name ?? '', declaredType: declaredType);
  if (mime.startsWith('video/')) return PickedMediaKind.video;
  if (mime.startsWith('image/') && !_isNonRenderableImage(name, extension)) {
    return PickedMediaKind.image;
  }
  return PickedMediaKind.file;   // 兜底永远走文件，不猜
}
```

- 判定优先级：**声明 mime → 文件名后缀 → `application/octet-stream` 兜底**，在后缀表里补齐 `webp / heic / heif / bmp / tiff / avif`（`media_mime_type.dart` 目前有 webp/heic/heif/bmp，缺 tiff/avif）；
- **`svg` 明确排除**（Flutter 无内建解码，按图片发出去只会渲染失败）→ 归 `file`；
- 手机端 `ImagePicker` 返回的 `XFile` 只有 path，后缀从 `p.basename(xFile.path)` 取（`mobile_chat_input.dart:200` 已经在这么做）。

把两条链路都收口到"分类后分发"：

```dart
// chat_input_controller.dart —— 一体化入口，替换 sendPickedImages / sendPickedFiles
Future<void> sendPickedAttachments(List<PlatformFile> files) async {
  for (final f in files) {
    switch (resolvePickedMediaKind(name: f.name, extension: f.extension)) {
      case PickedMediaKind.image: /* kind=IMAGE, MessageType.image, 读宽高 */
      case PickedMediaKind.video: /* kind=VIDEO, MessageType.video, 提取时长/封面 */
      case PickedMediaKind.file:  /* kind=FILE,  MessageType.file */
    }
  }
}
```

```dart
// chat_file_upload_controller.dart:54 selectFiles（桌面/Web）
// pick 返回后先分类：图片 → 插 BlockEmbed.imageType 并交给 ChatImageUploadController 上传；
// 其余保持现状（video / 其它都插 file embed）。这样"编辑器所见"与"发送后类型"才一致。
```

```dart
// chat_input_controller.dart:361 图片发送分支
// 上传结果查询必须把两个上传控制器都算上（或统一由图片控制器上传），
// 否则桌面端经"文件"入口选的图片永远拿不到 width/height。
```

### 2.4 手机端 UI 侧

`_pickAndSend(FileType.any, false)`（`mobile_chat_input.dart:131`）之后**不再需要 `isImage` 参数** —— 分类在控制器里做，UI 只负责"选文件 / 选图片"两种 picker。
`isImage` 仅保留用于决定是否走 `ImagePicker` + 裁剪那套真机流程。

---

## 三、改动清单

| 文件 | 改动 |
|---|---|
| `lib/common/utils/media_kind_resolver.dart` | **新增**：统一媒体类型分类器 |
| `lib/common/widgets/attachment_image_view.dart` | **新增**：本地/远程通用图片视图（从 `quill_image_build.dart` 抽出） |
| `framework/provider/chat/input/chat_input_controller.dart` | `_doSend` 加 `clientMsgId`；新增 `sendPickedAttachments`；`sendPickedImages/Files` 收口或删除；`_readImageSize*` 改读文件头；`_pruneDeletedUploads` 加保护；`:361` 图片分支结果查询覆盖两个控制器 |
| `framework/provider/chat/input/chat_image_upload_controller.dart` | `retain` 只清编辑器来源 id；`_readImageSize*` 收敛 |
| `framework/provider/chat/input/chat_file_upload_controller.dart` | `selectFiles` 分类分流；`retain` 同上；补 `bytesOf(id)`；`_readImageSize` 复用公共实现 |
| `framework/provider/chat/message/room_message_service.dart` | `upsertMessage`（`:350`）不落库"含本地媒体 url"的消息 |
| `framework/local_cache/local_data_source.dart` | `pendingOutgoingMessages()`（`:335`）过滤本地媒体 url |
| `features/chat/presentation/widgets/message_bubble/message_status_indicators.dart` | 上传中 / 失败态与重试入口 |
| `features/chat/presentation/widgets/message_render/image_message_strategy.dart` | 本地预览 + 上传遮罩；本地期间禁用大图 Hero |
| `features/chat/presentation/widgets/message_render/file_message_widgets.dart` | 上传中遮罩 / 进度；本地期间禁用下载 |
| `features/chat/.../chatinput/mobile/mobile_chat_input.dart` | `_pickAndSend` 立即收面板、改调 `sendPickedAttachments` |
| `features/chat/.../chatinput/desktop/quill/embedBuilder/quill_image_build.dart` | 改用抽出的 `AttachmentImageView` |
| `assets/i18n/{zh,en,ja}.json` | 复用 `chat_upload_progress` / `chat_uploaded` / `upload_failed` / `upload_failed_retry`；如需"重试上传"新增键（三语同位置插入） |

---

## 四、验证清单

- [ ] 手机端：选 1 张 10MB 图 → 面板立刻收、气泡 ≤300ms 出现、进度按百分比推进、完成后**原地**变清晰图、状态转已发送
- [ ] 手机端：选 3 个文件（含 1 图 1 视频 1 pdf）→ 分别渲染为 图片 / 视频 / 文件 气泡
- [ ] 手机端：飞行模式下选图 → 气泡先出现、转失败态、点重试能重新上传并发出
- [ ] 桌面 / Web：「文件」入口选 jpg → 编辑器内是**图片预览**、发出后是**图片消息**且宽高正确
- [ ] 断网重连不重放本地路径：检查 drift `pendingOutgoingMessages()` 与 WS 帧 payload 中不存在 `file://` / 本地绝对路径
- [ ] `flutter analyze` 无 issue；`flutter test test/framework/codec/im_packet_v6_test.dart` 通过
- [ ] 改 `@riverpod` / drift / 路由后跑 `dart run build_runner build --delete-conflicting-outputs`，`.g.dart` 一并提交

---

## 五、建议实施顺序

1. **P0 · 问题 2**：`media_kind_resolver` + `sendPickedAttachments` 分类分发（改动小、收益直接、无 UI 风险）
2. **P0 · 问题 1 Step 1-3**：`_doSend(clientMsgId)` + 乐观插入 + `upsertMessage` 落库守卫
3. **P1 · 问题 1 Step 4-5**：气泡进度 UI + `AttachmentImageView` + 尺寸读取优化
4. **P1 · 1.5 的坑**：`retain` 保护、失败重传、Hero/下载禁用
5. **P2**：上传超时/取消、四条 `_readImageSize` 实现收敛、`_isVideoExtension` 去重
