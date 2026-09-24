// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/utils/emoji_util.dart';
import 'package:anoxia/common/utils/media_kind_resolver.dart';
import 'package:anoxia/common/utils/media_mime_type.dart';
import 'package:anoxia/common/utils/media_url_util.dart';
import 'package:anoxia/framework/provider/core/toast_service_provider.dart';
import 'package:anoxia/framework/provider/core/upload_repository_provider.dart';
import 'package:anoxia/framework/codec/v6/im_packet_v6.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/sticker_pack.dart';
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:anoxia/framework/protocol/message/code_payload.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/framework/protocol/message/room_message.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/input/delta_processor.dart';
import 'package:anoxia/framework/provider/chat/input/upload_validator.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_limit.dart';
import 'package:anoxia/framework/provider/chat/input/chat_file_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_image_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/reply_target_provider.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:anoxia/framework/logs/debug_log.dart';
import '../room/room_member_service.dart';

part 'chat_input_controller.g.dart';

/// 聊天输入控制器
///
/// 负责管理聊天输入框的 QuillController，处理文本输入、@提及、图片/文件上传、
/// 消息发送（文本、富文本、表情、图片、文件、语音、卡片、位置）、输入状态通知、
/// 回复目标、输入超时等核心交互逻辑。
@Riverpod(keepAlive: true)
class ChatInputController extends _$ChatInputController {
  bool _isTyping = false;
  bool _isEnforcingInputLimit = false;
  bool _isSending = false;
  DateTime? _lastLimitNoticeAt;
  Timer? _typingTimer;
  Timer? _typingThrottle;

  /// 「即时发送」链路里仍在上传/待重传的本地草稿（key = clientMsgId）
  ///
  /// 只在内存里，应用重启即丢失 —— 与"本地文件已不可用"的事实相符。
  final Map<String, _LocalMediaDraft> _pendingMedia = {};

  /// 计算发送超时时间（秒）
  ///
  /// 根据消息类型和附件数量动态计算：
  /// - 基础值 10 秒 + 每个附件 2 秒
  /// - 若为音频、文件或视频类型额外加 5 秒
  /// - 最终限制在 10~30 秒之间
  int _resolveSendTimeoutSeconds({
    required MessageType type,
    List<Attachment>? attachments,
  }) {
    final attachmentCount = attachments?.length ?? 0;
    var timeout = 10 + (attachmentCount * 2);

    if (type == MessageType.audio ||
        type == MessageType.file ||
        type == MessageType.video) {
      timeout += 5;
    }

    return timeout.clamp(10, 30);
  }

  /// 构建 QuillController 实例
  ///
  /// 配置剪贴板行为，支持图片粘贴处理（通过 ChatImageUploadController 上传），
  /// 普通文本粘贴直接返回原文本。
  /// 同时监听文本变化（_onTextChanged）以触发@提及检测和输入状态通知。
  @override
  QuillController build(String roomId) {
    late QuillController controller;

    controller = QuillController.basic(
      config: QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(
          enableExternalRichPaste: false, // 禁止外部富文本粘贴，仅保留纯文本
          // --- 图片粘贴处理 ---
          onImagePaste: (Uint8List imageBytes) async {
            // 将粘贴的图片交给 ChatImageUploadController 上传，
            // 上传完成后会自动插入到编辑器（通过 Delta 插入图片标记）
            await ref
                .read(chatImageUploadControllerProvider.notifier)
                .handlePastedImage(controller, imageBytes);

            // 返回 null 表示不执行 Quill 默认的图片插入行为
            return null;
          },

          // 普通文本粘贴直接返回原文本
          onPlainTextPaste: (String plainText) async {
            if (!ChatInputLimit.canPaste(controller, plainText)) {
              _showInputLimitNotice();
              return '';
            }
            return plainText;
          },
        ),
      ),
    );

    // 监听文本变化
    controller.addListener(_onTextChanged);

    ref.onDispose(() {
      _typingTimer?.cancel();
      _typingThrottle?.cancel();
      controller.dispose();
    });

    return controller;
  }

  /// 文本变化回调
  ///
  /// 处理逻辑：
  /// - 若内容非空且未在输入状态，发送输入状态（正在输入）
  /// - 重置输入状态定时器（2秒后自动结束输入状态）
  /// - 检测 '@' 字符以显示@提及选择器，并实时更新搜索文本
  /// - 若光标离开 @ 区域（输入空格、换行或位置变化）则自动关闭提及选择器
  void _onTextChanged() {
    if (!ref.mounted) return;
    final controller = state;
    _pruneDeletedUploads(controller);
    if (_enforceInputLimit(controller)) return;
    final bool hasContent = controller.document.length > 1;

    if (hasContent) {
      _isTyping = true;
      _sendTypingStatus(true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (!ref.mounted) return;
      if (_isTyping) {
        _isTyping = false;
        _sendTypingStatus(false);
      }
    });

    // 延迟执行光标位置和@提及检测，确保 UI 更新完成
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!ref.mounted) return;

      final selection = controller.selection;

      if (selection.baseOffset > 0) {
        final plainText = controller.document.toPlainText();
        final cursorPosition = selection.baseOffset;

        // 当光标前一个字符是 '@' 时，显示提及选择器
        if (cursorPosition <= plainText.length &&
            plainText[cursorPosition - 1] == '@') {
          ref.read(mentionStateProvider.notifier).show(cursorPosition, '');
          return;
        }

        // 若当前正在显示提及选择器，则根据光标位置更新或关闭
        final mentionState = ref.read(mentionStateProvider);
        if (mentionState.isShowing) {
          // 如果光标位置退回到 @ 之前，隐藏选择器
          if (cursorPosition < mentionState.cursorPosition) {
            ref.read(mentionStateProvider.notifier).hide();
            return;
          }

          // 如果 @ 符号被删除，隐藏选择器
          if (mentionState.cursorPosition > 0 &&
              mentionState.cursorPosition - 1 < plainText.length &&
              plainText[mentionState.cursorPosition - 1] != '@') {
            ref.read(mentionStateProvider.notifier).hide();
            return;
          }

          // 提取 @ 到当前光标之间的文本作为搜索关键字
          final textAfterAt = plainText.substring(
            mentionState.cursorPosition,
            cursorPosition.clamp(mentionState.cursorPosition, plainText.length),
          );

          // 如果包含空格或换行，认为 @ 提及结束，隐藏选择器
          if (textAfterAt.contains(' ') || textAfterAt.contains('\n')) {
            ref.read(mentionStateProvider.notifier).hide();
          } else {
            ref.read(mentionStateProvider.notifier).updateSearch(textAfterAt);
          }
        }
      } else {
        // 光标在文档开头时，若选择器显示则隐藏
        final mentionState = ref.read(mentionStateProvider);
        if (mentionState.isShowing) {
          ref.read(mentionStateProvider.notifier).hide();
        }
      }
    });
  }

  /// 清理已从编辑器中删除的附件上传记录。
  ///
  /// 用户退格删除图片/文件 embed 后，上传控制器中仍残留 uploading/failed
  /// 记录，导致发送按钮永久禁用（Web/桌面端 Quill 输入框）。每次文档变更
  /// 时按当前文档内的附件 ID 裁剪两个上传控制器。
  ///
  /// 裁剪范围由控制器内部的「编辑器归属」集合限定：移动端「即时发送」链路
  /// 的附件不在编辑器文档里，传空集合不会误伤它们（上传不会被静默取消）。
  void _pruneDeletedUploads(QuillController controller) {
    final ids = DeltaProcessor(
      controller.document.toDelta(),
      const {},
    ).attachmentIds;
    ref.read(chatImageUploadControllerProvider.notifier).retain(ids);
    ref.read(chatFileUploadControllerProvider.notifier).retain(ids);
  }

  /// 发送输入状态（正在输入/结束输入）给聊天对方
  ///
  /// 通过 WebSocket 发送 HighMessage 类型 TYPING_STATUS，
  /// 前提是对方在线且房间成员已同步。
  bool _enforceInputLimit(QuillController controller) {
    if (_isEnforcingInputLimit) return true;
    if (controller.document.length <= ChatInputLimit.maxCharacters + 1) {
      return false;
    }

    _isEnforcingInputLimit = true;
    try {
      final excess =
          controller.document.length - ChatInputLimit.maxCharacters - 1;
      controller.replaceText(
        ChatInputLimit.maxCharacters,
        excess,
        '',
        const TextSelection.collapsed(offset: ChatInputLimit.maxCharacters),
      );
      _showInputLimitNotice();
    } finally {
      _isEnforcingInputLimit = false;
    }
    return true;
  }

  void _showInputLimitNotice() {
    final now = DateTime.now();
    if (_lastLimitNoticeAt != null &&
        now.difference(_lastLimitNoticeAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastLimitNoticeAt = now;
    ref
        .read(toastServiceProvider)
        .showToast(
          'chat_input_length_limit'.tr(
            args: [ChatInputLimit.maxCharacters.toString()],
          ),
          type: ToastType.warning,
        );
  }

  void _sendTypingStatus(bool isTyping) {
    if (!ref.mounted) return;
    if (isTyping && _typingThrottle != null) return;
    final room = ref.read(currentRoomProvider(roomId));
    if (room == null || room.peerId == null) return;

    final roomMembers = ref.read(roomMembersProvider(room.roomId!));

    // 成员未同步则跳过
    if (roomMembers.isEmpty) {
      return;
    }

    // 查找对方成员
    final matchedMembers = roomMembers
        .where((member) => member.userId == room.peerId)
        .toList();
    final peerMember = matchedMembers.isEmpty ? null : matchedMembers.first;

    if (peerMember == null) return;

    // 对方不在线则不发送
    if (peerMember.onlineStatus != true) {
      return;
    }

    _typingThrottle?.cancel();
    _typingThrottle = isTyping
        ? Timer(const Duration(seconds: 3), () => _typingThrottle = null)
        : null;
    ref
        .read(wsControllerProvider.notifier)
        .sendMessage(ImPacketV6.encodeTypingFrame(room.roomId!, isTyping));
  }

  /// 发送消息（从编辑器内容构建）
  ///
  /// 处理流程：
  /// 1. 获取当前房间和编辑器内容
  /// 2. 检查图片/文件上传状态，若有正在上传或失败则中止
  /// 3. 通过 DeltaProcessor 处理 Delta，提取图片、文件、纯文本、@提及、表情等
  /// 4. 分别发送图片、文件、表情或文本/富文本消息
  /// 5. 清空输入框并恢复焦点（桌面端）
  Future<void> sendMessage() async {
    if (_isSending) return;
    final room = ref.read(currentRoomProvider(roomId));
    if (room == null || room.isOfficial || state.document.isEmpty()) return;
    _isSending = true;
    try {
      await _sendMessageInternal();
    } finally {
      _isSending = false;
    }
  }

  /// 发送消息的内部实现（由 [sendMessage] 加防重入锁后调用）
  ///
  /// 处理流程：见 [sendMessage]。
  Future<void> _sendMessageInternal() async {
    final room = ref.read(currentRoomProvider(roomId));
    final uploadState = {
      ...ref.read(chatImageUploadControllerProvider.notifier).urlMap,
      ...ref.read(chatFileUploadControllerProvider.notifier).urlMap,
    };
    final processor = DeltaProcessor(state.document.toDelta(), uploadState);
    final mentionIds = processor.mentionedUserIds;
    final mentionAll = processor.mentionAll;

    final imageState = ref.read(chatImageUploadControllerProvider);
    final fileState = ref.read(chatFileUploadControllerProvider);
    final allEntries = [...imageState.values, ...fileState.values];

    // 如果有文件正在上传或上传失败，不发送
    if (allEntries.any((e) => e.isUploading)) return;
    if (allEntries.any((e) => e.isFailed)) return;

    // 所有附件必须已上传完成
    if (!processor.isAllUploaded) {
      return;
    }

    // --- 发送图片 ---
    if (processor.images.isNotEmpty) {
      final imageUploader = ref.read(
        chatImageUploadControllerProvider.notifier,
      );
      for (final image in processor.images) {
        final uploaded = imageUploader.uploadResultOf(image.id);
        final enhanced = image.copyWith(
          url: uploaded?.url,
          width: uploaded?.width,
          height: uploaded?.height,
        );
        _doSend(
          type: MessageType.image,
          payload: const MessagePayload(content: '[image]'),
          attachments: [enhanced],
          clearReplyAfterSend: false,
        );
      }
    }

    // --- 发送视频（从文件嵌入中自动识别的视频） ---
    // VIDEO 守卫要求 durationMs 非空，优先用上传时提取的真实时长，
    // 未知时回退 1s 占位并补充宽高，避免 CRITICAL 与气泡宽高缺失。
    if (processor.videos.isNotEmpty) {
      final fileUploader = ref.read(chatFileUploadControllerProvider.notifier);
      // 发送前置提取真实元数据（避免与上传完成提取的竞态导致回退占位时长）
      await fileUploader.ensureVideoMetadata(processor.videos);
      for (final video in processor.videos) {
        final uploaded = fileUploader.uploadResultOf(video.id);
        final meta = fileUploader.videoMetadataOf(video.id);
        final duration = uploaded?.durationMs ?? meta?.durationMs ?? 1000;
        final enhanced = video.copyWith(
          url: uploaded?.url,
          width: uploaded?.width ?? meta?.width,
          height: uploaded?.height ?? meta?.height,
          bitrate: uploaded?.bitrate,
          thumbnailUrl: uploaded?.coverUrl,
        );
        final coverUrl = uploaded?.coverUrl;
        _doSend(
          type: MessageType.video,
          payload: MessagePayload(content: '[video]', audioDuration: duration),
          attachments: [
            enhanced,
            if (coverUrl != null && coverUrl.isNotEmpty)
              Attachment(
                kind: 'IMAGE',
                url: coverUrl,
                name: 'cover.jpg',
                type: 'image/jpeg',
                size: uploaded?.coverSizeBytes,
              ),
          ],
          clearReplyAfterSend: false,
        );
      }
    }

    // --- 发送文件 ---
    if (processor.files.isNotEmpty) {
      for (final file in processor.files) {
        _doSend(
          type: MessageType.file,
          payload: const MessagePayload(content: '[file]'),
          attachments: [file],
          clearReplyAfterSend: false,
        );
      }
    }

    // --- 发送文本/富文本/表情 ---
    if (processor.plainText.isNotEmpty ||
        processor.mentionedUserIds.isNotEmpty ||
        processor.mentionAll) {
      final cleanDelta = processor.filteredDelta;
      // 如果 Delta 为空或仅包含换行且无 @提及，则忽略
      if (cleanDelta.length == 0 ||
          (cleanDelta.length == 1 &&
              cleanDelta.first.data == '\n' &&
              processor.mentionedUserIds.isEmpty &&
              !processor.mentionAll)) {
        return;
      }

      // 单个表情符号作为 Emoji 消息发送
      if (processor.isSingleEmoji) {
        final emoji = processor.plainText.characters.first;
        _doSend(
          type: MessageType.emoji,
          payload: MessagePayload(content: emoji, emojiCode: emoji),
          clearReplyAfterSend: false,
        );
      } else {
        final isRich =
            processor.hasAttributes || mentionIds.isNotEmpty || mentionAll;
        _doSend(
          type: isRich ? MessageType.richText : MessageType.text,
          payload: isRich
              ? MessagePayload(
                  content: processor.plainText.characters.take(100).toString(),
                  quillDelta: jsonEncode(cleanDelta.toJson()),
                  mentions: mentionIds,
                  mentionAll: mentionAll,
                )
              : MessagePayload(content: processor.plainText),
          clearReplyAfterSend: false,
        );
      }
    }

    // 4. 清空输入框
    clearInput();
    if (DeviceUtil.isRealDesktop()) {
      ref.read(chatFocusNodeProvider(room?.roomId ?? '')).requestFocus();
    }
  }

  /// 发送移动端含 @提及的富文本消息。
  ///
  /// [quillDelta] 为由 [MobileTextInputController.buildSendData] 生成的
  /// Quill Delta JSON 字符串，格式与桌面端一致，渲染效果与桌面端保持统一。
  void sendMobileMentionMessage(
    String text,
    String quillDelta, {
    List<int>? mentionIds,
    bool mentionAll = false,
  }) {
    final room = ref.read(currentRoomProvider(roomId));
    final content = text.trim();
    if (room == null || content.isEmpty) return;

    _doSend(
      type: MessageType.richText,
      payload: MessagePayload(
        content: content.characters.take(100).toString(),
        quillDelta: quillDelta,
        mentions: (mentionIds != null && mentionIds.isNotEmpty)
            ? mentionIds
            : null,
        mentionAll: mentionAll,
      ),
    );
  }

  /// 发送纯文本消息（Android 专用或外部调用）
  ///
  /// 若文本为单个表情符号，则作为 Emoji 消息发送。
  void sendPlainTextMessage(
    String text, {
    List<int>? mentionIds,
    bool mentionAll = false,
  }) {
    final room = ref.read(currentRoomProvider(roomId));
    final content = text.trim();
    if (room == null || content.isEmpty) return;

    final isSingleEmoji = EmojiUtil.isSingleEmoji(content);

    _doSend(
      type: isSingleEmoji ? MessageType.emoji : MessageType.text,
      payload: MessagePayload(
        content: content,
        mentions: (mentionIds != null && mentionIds.isNotEmpty)
            ? mentionIds
            : null,
        mentionAll: mentionAll,
        emojiCode: isSingleEmoji ? content.characters.first : null,
      ),
    );
  }

  /// 发送贴图表情（表情包）
  ///
  /// 以 [MessageType.emoji] 消息发送：[emojiCode] = 表情标识，
  /// [asset] = 表情图片 URL/宽高，对端按图片渲染。
  void sendStickerMessage(Sticker sticker) {
    final room = ref.read(currentRoomProvider(roomId));
    if (room == null) return;

    _doSend(
      type: MessageType.emoji,
      payload: MessagePayload(
        content: sticker.stickerKey,
        emojiCode: sticker.stickerKey,
        asset: Attachment(
          url: sticker.imageUrl,
          width: sticker.width,
          height: sticker.height,
          kind: 'FILE',
        ),
      ),
    );
  }

  /// 发送卡片消息
  bool sendCardMessage(CardPayload card) {
    final room = ref.read(currentRoomProvider(roomId));
    final title = card.displayTitle.trim();
    if (room == null || title.isEmpty) return false;

    _doSend(
      type: MessageType.card,
      payload: MessagePayload(content: title, card: card),
    );
    return true;
  }

  /// 发送位置消息
  void sendLocationMessage(LocationPayload location) {
    final room = ref.read(currentRoomProvider(roomId));
    final title = location.displayTitle.trim();
    if (room == null || title.isEmpty || !location.hasCoordinate) return;

    _doSend(
      type: MessageType.location,
      payload: MessagePayload(content: title, location: location),
    );
  }

  /// 「即时发送」：选中一批文件后**立即**插入本地气泡，再后台上传并发出
  ///
  /// 旧实现是「先上传、后插入」（`await uploader.upload*()` 排在 `_doSend`
  /// 之前），气泡出现的时刻等于整条上传完成的时刻，中途没有任何反馈。
  /// 现在改为：先插本地气泡（本地预览 + 上传进度），上传完再原地替换。
  ///
  /// 约定：`clientMsgId == attachment.id == clientFileId`，
  /// 气泡据此直接查到进度与本地字节（见 `AttachmentUploadOverlay`）。
  ///
  /// 媒体类型由 [resolvePickedMediaKind] 动态判定：「文件」入口选到图片
  /// 也会走图片消息，不会退化成文件卡片。
  Future<void> sendPickedAttachments(List<PlatformFile> files) async {
    if (files.isEmpty) return;
    final room = ref.read(currentRoomProvider(roomId));
    final user = ref.read(authControllerProvider).value;
    if (room == null || user == null) return;

    final toast = ref.read(toastServiceProvider);
    final drafts = <_LocalMediaDraft>[];
    for (final file in files) {
      if (!UploadValidator.validateSingleFile(toast, file)) continue;
      drafts.add(_buildLocalMediaDraft(file));
    }
    if (drafts.isEmpty) return;

    // 1. 先把本地气泡插进去（payload 指向本地文件，消息只存在于内存）
    for (final draft in drafts) {
      _pendingMedia[draft.clientMsgId] = draft;
      ref
          .read(chatMessagesProvider.notifier)
          .upsertMessage(
            _buildLocalMediaMessage(draft, DeliveryStatus.sending),
          );
    }

    // 2. 后台上传（按控制器分批，保持各自 2 路的并发上限）
    await _uploadLocalMediaBatch(drafts);

    // 3. 逐个落地：成功 → 原地替换为服务器资源并发出；失败 → 转失败态
    for (final draft in drafts) {
      _finalizeLocalMediaDraft(draft);
    }
  }

  /// 重传并重新发送一条媒体仍指向本地文件的失败消息
  ///
  /// 返回 `false` 表示本地文件已丢失（如应用重启后内存草稿被清），无法重传。
  Future<bool> retryLocalMediaMessage(ChatMessage message) async {
    final id = message.clientMsgId ?? message.messageId;
    if (id == null || id.isEmpty) return false;
    final draft = _pendingMedia[id];
    if (draft == null) return false;

    ref
        .read(chatMessagesProvider.notifier)
        .upsertMessage(_buildLocalMediaMessage(draft, DeliveryStatus.sending));
    await _uploadLocalMediaBatch([draft]);
    _finalizeLocalMediaDraft(draft);
    return true;
  }

  /// 构建本地媒体草稿（本地文件 + 附件 + 目标消息类型）
  ///
  /// 同步方法：媒体类型判定与附件组装都不需要 IO，图片宽高由读取方
  /// （上传控制器 / 气泡）按需补齐，避免"选完到可见"之间再插一次等待。
  _LocalMediaDraft _buildLocalMediaDraft(PlatformFile file) {
    final id = const Uuid().v4();
    final mime = mediaMimeTypeForName(file.name);
    // Web 端 path 为 null，用合成地址保证 mediaAttachments 非空
    final localUrl = file.path ?? localPendingMediaUrl(id);
    return switch (resolvePickedMediaKind(
      name: file.name,
      extension: file.extension,
    )) {
      PickedMediaKind.image => _LocalMediaDraft(
        clientMsgId: id,
        file: file,
        messageType: MessageType.image,
        attachment: Attachment(
          id: id,
          kind: 'IMAGE',
          url: localUrl,
          name: file.name,
          size: file.size,
          type: mime,
        ),
      ),
      PickedMediaKind.video => _LocalMediaDraft(
        clientMsgId: id,
        file: file,
        messageType: MessageType.video,
        attachment: Attachment(
          id: id,
          kind: 'VIDEO',
          url: localUrl,
          name: file.name,
          size: file.size,
          type: mime,
        ),
      ),
      PickedMediaKind.file => _LocalMediaDraft(
        clientMsgId: id,
        file: file,
        messageType: MessageType.file,
        attachment: Attachment(
          id: id,
          kind: 'FILE',
          url: localUrl,
          name: file.name,
          size: file.size,
          type: mime,
        ),
      ),
    };
  }

  /// 构建（或重建）本地媒体消息
  ///
  /// 时间戳固定在草稿上，重传时不会因为换新时间戳而在列表里跳位。
  ChatMessage _buildLocalMediaMessage(
    _LocalMediaDraft draft,
    DeliveryStatus status,
  ) {
    final userId = ref.read(authControllerProvider).value?.userId;
    final payload = MessagePayload(
      content: _mediaPlaceholderContent(draft.messageType),
    ).withMedia(draft.messageType, [draft.attachment]);
    return ChatMessage(
      messageId: draft.clientMsgId,
      clientMsgId: draft.clientMsgId,
      roomId: roomId,
      senderId: userId,
      messageType: draft.messageType,
      content: payload.content ?? '',
      payload: payload,
      timestamp: draft.timestamp,
      deliveryStatus: status,
      seq: 0,
    );
  }

  /// 会话列表预览用的占位文案，与发送后的取值保持一致
  String _mediaPlaceholderContent(MessageType type) => switch (type) {
    MessageType.image => '[image]',
    MessageType.video => '[video]',
    _ => '[file]',
  };

  /// 按上传控制器分批上传整批草稿
  ///
  /// 图片走图片控制器、视频与文件走文件控制器，各自内部并发上限为 2，
  /// 不逐个文件各起一个请求（否则并发会随文件数线性增长）。
  Future<void> _uploadLocalMediaBatch(List<_LocalMediaDraft> drafts) async {
    final imageDrafts = drafts
        .where((draft) => draft.messageType == MessageType.image)
        .toList();
    final otherDrafts = drafts
        .where((draft) => draft.messageType != MessageType.image)
        .toList();

    final futures = <Future<void>>[];
    if (imageDrafts.isNotEmpty) {
      futures.add(
        ref
            .read(chatImageUploadControllerProvider.notifier)
            .uploadImages(
              imageDrafts.map((draft) => draft.attachment).toList(),
              pickedFiles: {
                for (final draft in imageDrafts) draft.clientMsgId: draft.file,
              },
            ),
      );
    }
    if (otherDrafts.isNotEmpty) {
      futures.add(
        ref
            .read(chatFileUploadControllerProvider.notifier)
            .uploadFiles(
              otherDrafts.map((draft) => draft.attachment).toList(),
              pickedFiles: {
                for (final draft in otherDrafts) draft.clientMsgId: draft.file,
              },
            ),
      );
    }
    if (futures.isEmpty) return;
    try {
      await Future.wait(futures);
    } catch (e, st) {
      debugLog('[即时发送] 附件上传异常: $e', st);
    }
  }

  /// 单个草稿的上传结果落地
  void _finalizeLocalMediaDraft(_LocalMediaDraft draft) {
    final id = draft.clientMsgId;
    final isImage = draft.messageType == MessageType.image;
    final imageUploader = ref.read(chatImageUploadControllerProvider.notifier);
    final fileUploader = ref.read(chatFileUploadControllerProvider.notifier);
    final serverUrl = isImage
        ? imageUploader.urlMap[id]
        : fileUploader.urlMap[id];

    if (serverUrl == null || serverUrl.isEmpty) {
      // 上传失败：保留气泡并转失败态，点击可重传（见 retryLocalMediaMessage）
      ref
          .read(chatMessagesProvider.notifier)
          .upsertMessage(_buildLocalMediaMessage(draft, DeliveryStatus.failed));
      return;
    }

    final result = isImage
        ? imageUploader.uploadResultOf(id)
        : fileUploader.uploadResultOf(id);
    final videoMeta = draft.messageType == MessageType.video
        ? fileUploader.videoMetadataOf(id)
        : null;
    final enhanced = draft.attachment.copyWith(
      url: serverUrl,
      width: result?.width ?? videoMeta?.width,
      height: result?.height ?? videoMeta?.height,
      bitrate: result?.bitrate,
      thumbnailUrl: result?.coverUrl,
    );
    final coverUrl = result?.coverUrl;

    if (draft.messageType == MessageType.image) {
      _doSend(
        type: MessageType.image,
        payload: const MessagePayload(content: '[image]'),
        attachments: [enhanced],
        clearReplyAfterSend: false,
        clientMsgId: id,
      );
    } else if (draft.messageType == MessageType.video) {
      _doSend(
        type: MessageType.video,
        // 占位时长 1s 满足服务端 VIDEO 守卫 durationMs 必填，避免 CRITICAL
        payload: MessagePayload(
          content: '[video]',
          audioDuration: result?.durationMs ?? videoMeta?.durationMs ?? 1000,
        ),
        attachments: [
          enhanced,
          if (coverUrl != null && coverUrl.isNotEmpty)
            Attachment(
              kind: 'IMAGE',
              url: coverUrl,
              name: 'cover.jpg',
              type: 'image/jpeg',
              size: result?.coverSizeBytes,
            ),
        ],
        clearReplyAfterSend: false,
        clientMsgId: id,
      );
    } else {
      _doSend(
        type: MessageType.file,
        payload: const MessagePayload(content: '[file]'),
        attachments: [enhanced],
        clearReplyAfterSend: false,
        clientMsgId: id,
      );
    }

    _pendingMedia.remove(id);
    if (isImage) {
      imageUploader.release(id);
    } else {
      fileUploader.release(id);
    }
    ref.read(replyTargetControllerProvider.notifier).clear(roomId);
  }

  /// 纯文本变更处理（用于 Android 等平台，类似 _onTextChanged 的简化版）
  ///
  /// 更新输入状态、重置定时器，但不处理 @提及（因为 Android 使用单独机制）。
  void handlePlainTextChanged(String text) {
    final hasContent = text.trim().isNotEmpty;

    if (hasContent) {
      _isTyping = true;
      _sendTypingStatus(true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (!ref.mounted) return;
      if (_isTyping) {
        _isTyping = false;
        _sendTypingStatus(false);
      }
    });

    if (!hasContent && _isTyping) {
      _isTyping = false;
      _sendTypingStatus(false);
    }
  }

  /// 发送语音消息
  ///
  /// 先创建本地消息（sending 状态），上传语音文件，成功后通过 WebSocket 发送真正的 RoomMessage，
  /// 并更新本地消息状态为 sent（由后续推送更新）。
  /// 若上传失败则标记为 failed。
  Future<void> sendVoiceMessage({
    required String filePath,
    required int durationMs,
  }) async {
    final room = ref.read(currentRoomProvider(roomId));
    if (room == null) return;

    final clientMsgId = const Uuid().v4();
    final file = File(filePath);
    final localAudioAttachments = [
      Attachment(
        id: clientMsgId,
        kind: 'AUDIO',
        url: filePath,
        name: 'voice_message',
        size: file.lengthSync(),
        type: 'audio/m4a',
      ),
    ];
    final localPayload = MessagePayload(
      content: '[audio]',
      audioDuration: durationMs,
    ).withMedia(MessageType.audio, localAudioAttachments);

    // 1. 先插入本地发送中的消息
    final localMsg = ChatMessage(
      messageId: clientMsgId,
      clientMsgId: clientMsgId,
      roomId: roomId,
      senderId: ref.read(authControllerProvider).value?.userId,
      messageType: MessageType.audio,
      content: localPayload.content ?? '',
      payload: localPayload,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      deliveryStatus: DeliveryStatus.sending,
      seq: 0,
    );

    ref.read(chatMessagesProvider.notifier).upsertMessage(localMsg);

    try {
      // 2. 上传语音文件
      final results = await ref
          .read(uploadRepositoryProvider)
          .uploadFiles([XFile(file.path)], clientFileIds: [clientMsgId]);

      if (results.isEmpty ||
          !results.first.isSuccess ||
          results.first.url == null) {
        // 上传失败，标记消息为 failed
        ref
            .read(chatMessagesProvider.notifier)
            .upsertMessage(
              localMsg.copyWith(deliveryStatus: DeliveryStatus.failed),
            );
        debugLog('voice upload failed: empty response');
        return;
      }

      final url = results.first.url!;

      // 3. 发送真正的语音消息
      _doSendVoice(
        clientMsgId: clientMsgId,
        url: url,
        durationMs: durationMs,
        fileSize: file.lengthSync(),
      );

      // 4. 删除本地临时文件
      try {
        file.deleteSync();
      } catch (_) {}
    } catch (e) {
      ref
          .read(chatMessagesProvider.notifier)
          .upsertMessage(
            localMsg.copyWith(deliveryStatus: DeliveryStatus.failed),
          );
      debugLog('语音消息发送异常: $e');
    }
  }

  /// 执行语音消息发送（通过 WebSocket）
  ///
  /// 更新本地消息（替换为真实 URL），发送 RoomMessage，并启动超时计时器。
  void _doSendVoice({
    required String clientMsgId,
    required String url,
    required int durationMs,
    required int fileSize,
  }) {
    final room = ref.read(currentRoomProvider(roomId));
    final user = ref.read(authControllerProvider).value;
    if (room == null || user == null) return;

    final attachments = [
      Attachment(
        id: clientMsgId,
        kind: 'AUDIO',
        url: url,
        name: 'voice_message',
        size: fileSize,
        type: 'audio/m4a',
      ),
    ];
    final payload = MessagePayload(
      content: '[audio]',
      audioDuration: durationMs,
    ).withMedia(MessageType.audio, attachments);

    // 更新本地消息，包含真实 url
    final updatedMsg = ChatMessage(
      messageId: clientMsgId,
      clientMsgId: clientMsgId,
      roomId: roomId,
      senderId: user.userId,
      messageType: MessageType.audio,
      content: '[audio]',
      payload: payload,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      deliveryStatus: DeliveryStatus.sending,
      seq: 0,
    );
    ref.read(chatMessagesProvider.notifier).upsertMessage(updatedMsg);

    final protoMsg = RoomMessage(
      messageId: '',
      clientMsgId: clientMsgId,
      roomId: roomId,
      senderId: user.userId,
      messageType: MessageType.audio,
      payload: payload,
      clientTimestamp: DateTime.now().millisecondsSinceEpoch,
    );

    final timeoutSeconds = _resolveSendTimeoutSeconds(
      type: MessageType.audio,
      attachments: attachments,
    );
    ref
        .read(wsControllerProvider.notifier)
        .sendMessage(
          ImPacketV6.encodeRoomMessageFrame(protoMsg),
          clientMsgId: clientMsgId,
          ackTimeout: Duration(seconds: timeoutSeconds),
        );
    ref.read(replyTargetControllerProvider.notifier).clear(roomId);
  }

  /// 清空输入框内容，重置输入状态，隐藏 @提及选择器，清除回复目标
  void clearInput() {
    state.clear();
    _isTyping = false;
    ref.read(mentionStateProvider.notifier).hide();
    ref.read(replyTargetControllerProvider.notifier).clear(roomId);
  }

  /// 为消息添加回复目标（如果消息类型支持且存在回复目标）
  MessagePayload _withReplyTarget(MessageType type, MessagePayload payload) {
    if (!_supportsInteraction(type)) return payload;

    final target = ref.read(replyTargetProvider(roomId));
    final messageId = target?.messageId;
    if (messageId == null || messageId.isEmpty) return payload;

    return payload.copyWith(replyTo: messageId);
  }

  /// 判断消息类型是否支持回复交互
  bool _supportsInteraction(MessageType type) {
    return type == MessageType.text ||
        type == MessageType.richText ||
        type == MessageType.image ||
        type == MessageType.file ||
        type == MessageType.video ||
        type == MessageType.codeSnippet;
  }

  /// 通用发送消息方法
  ///
  /// 创建本地消息（sending 状态），发送 RoomMessage 到 WebSocket，并启动超时计时器。
  /// 支持附件、回复目标等。
  ///
  /// [clientMsgId] 用于「即时发送」链路：本地气泡已经用这个 id 插入过，
  /// 这里必须复用同一个 id，服务端回包才能原地替换掉乐观气泡。
  void _doSend({
    required MessageType type,
    required MessagePayload payload,
    List<Attachment>? attachments,
    bool clearReplyAfterSend = true,
    String? clientMsgId,
  }) {
    final String resolvedClientMsgId = clientMsgId ?? const Uuid().v4();
    final user = ref.read(authControllerProvider).value;
    if (user == null) {
      debugLog('send failed: missing user');
      return;
    }
    final payloadWithReply = _withReplyTarget(type, payload);
    final payloadWithMedia = payloadWithReply.withMedia(
      type,
      attachments ?? const [],
    );
    final derivedAttachments = payloadWithMedia.mediaAttachments;

    final localMsg = ChatMessage(
      messageId: resolvedClientMsgId,
      clientMsgId: resolvedClientMsgId,
      roomId: roomId,
      senderId: user.userId,
      messageType: type,
      content: payloadWithMedia.content ?? '',
      payload: payloadWithMedia,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      deliveryStatus: DeliveryStatus.sending,
      seq: 0,
    );

    ref.read(chatMessagesProvider.notifier).upsertMessage(localMsg);

    final protoMsg = RoomMessage(
      messageId: '',
      clientMsgId: resolvedClientMsgId,
      roomId: roomId,
      senderId: user.userId,
      messageType: type,
      payload: payloadWithMedia,
      clientTimestamp: DateTime.now().millisecondsSinceEpoch,
    );

    final timeoutSeconds = _resolveSendTimeoutSeconds(
      type: type,
      attachments: derivedAttachments,
    );
    ref
        .read(wsControllerProvider.notifier)
        .sendMessage(
          ImPacketV6.encodeRoomMessageFrame(protoMsg),
          clientMsgId: resolvedClientMsgId,
          ackTimeout: Duration(seconds: timeoutSeconds),
        );
    if (clearReplyAfterSend) {
      ref.read(replyTargetControllerProvider.notifier).clear(roomId);
    }
  }

  /// 发送代码片段消息
  ///
  /// 从代码编辑对话框调用，直接发送代码消息，不经过 Quill 编辑器。
  /// 本地预览 content 使用标题或代码首行（会话列表展示用），
  /// 无有效文本时留空，由预览层按当前语言展示本地化占位。
  bool sendCodeMessage(CodePayload codePayload) {
    if (!codePayload.isValid) return false;
    final room = ref.read(currentRoomProvider(roomId));
    if (room == null) return false;

    _doSend(
      type: MessageType.codeSnippet,
      payload: MessagePayload(
        content: codePayload.previewSnippet,
        code: codePayload,
      ),
    );
    return true;
  }
}

/// 「即时发送」链路的本地媒体草稿
///
/// 记录本地文件与目标消息类型，供「先插气泡、后台上传、上传失败可重传」使用。
/// 只存在于内存（`ChatInputController._pendingMedia`）。
class _LocalMediaDraft {
  _LocalMediaDraft({
    required this.clientMsgId,
    required this.attachment,
    required this.file,
    required this.messageType,
  }) : timestamp = DateTime.now().millisecondsSinceEpoch;

  /// 同时作为 `attachment.id`、上传的 `clientFileId` 与消息 id
  final String clientMsgId;

  /// 附件（url 先指向本地文件，上传成功后替换为服务器地址）
  final Attachment attachment;

  /// 本地选中的文件（Web 端只有 bytes，用于本地预览与重传）
  final PlatformFile file;

  /// 目标消息类型（由媒体类型动态判定得出）
  final MessageType messageType;

  /// 乐观气泡的固定时间戳：重传时不换时间戳，避免在列表里跳位
  final int timestamp;
}

/// 聊天输入框的焦点节点 Provider
///
/// 用于在发送消息后（桌面端）自动获取焦点。
@riverpod
FocusNode chatFocusNode(Ref ref, String roomId) {
  final node = FocusNode();
  ref.onDispose(() => node.dispose());
  return node;
}

/// @提及状态管理
///
/// 用于管理 @ 提及选择器的显示/隐藏、搜索文本、光标位置等信息。
@Riverpod(keepAlive: true)
class MentionState extends _$MentionState {
  @override
  MentionStateData build() => MentionStateData();

  /// 显示提及选择器，记录当前光标位置和 @ 符号的坐标（用于定位弹出框）
  void show(int cursorPosition, String searchText, {Offset? atSymbolOffset}) {
    state = state.copyWith(
      isShowing: true,
      cursorPosition: cursorPosition,
      searchText: searchText,
      atSymbolOffset: atSymbolOffset,
      selectedIndex: 0,
    );
  }

  /// 隐藏提及选择器
  void hide() {
    state = state.copyWith(isShowing: false, selectedIndex: 0);
  }

  /// 更新搜索文本（用户输入了更多字符）
  void updateSearch(String text) {
    state = state.copyWith(searchText: text, selectedIndex: 0);
  }

  /// 更新键盘选中的用户索引
  void updateSelectedIndex(int index) {
    state = state.copyWith(selectedIndex: index);
  }
}

/// @提及状态数据类
///
/// 包含是否显示、光标位置、搜索关键字、@符号偏移量（用于定位）、键盘选中索引。
class MentionStateData {
  final bool isShowing;
  final int cursorPosition;
  final String searchText;
  final Offset? atSymbolOffset; // @ 符号在屏幕上的偏移，用于锚定弹出层
  final int selectedIndex; // 键盘上下键选中的用户索引（-1 表示未选中）

  MentionStateData({
    this.isShowing = false,
    this.cursorPosition = 0,
    this.searchText = '',
    this.atSymbolOffset,
    this.selectedIndex = 0,
  });

  MentionStateData copyWith({
    bool? isShowing,
    int? cursorPosition,
    String? searchText,
    Offset? atSymbolOffset,
    int? selectedIndex,
  }) {
    return MentionStateData(
      isShowing: isShowing ?? this.isShowing,
      cursorPosition: cursorPosition ?? this.cursorPosition,
      searchText: searchText ?? this.searchText,
      atSymbolOffset: atSymbolOffset ?? this.atSymbolOffset,
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }
}
