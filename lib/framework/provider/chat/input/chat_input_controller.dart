// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/framework/codec/v5/ImPacketV5.dart';
import 'package:anoxia/framework/domain/ChatMessage.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/protocol/message/Attachment.dart';
import 'package:anoxia/framework/protocol/message/MessageEunm.dart';
import 'package:anoxia/framework/protocol/message/MessagePayload.dart';
import 'package:anoxia/framework/protocol/message/HighMessage.dart';
import 'package:anoxia/framework/protocol/message/RoomMessage.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/input/DeltaProcessor.dart';
import 'package:anoxia/framework/provider/chat/input/UploadValidator.dart';
import 'package:anoxia/framework/provider/chat/input/files/chat_file_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/images/chat_image_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/reply_target_provider.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../logs/talker.dart';
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
  Timer? _typingTimer;

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
            log.info('pasted image bytes: ${imageBytes.lengthInBytes}');

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
            log.info('onPlainTextPaste: $plainText');
            return plainText;
          },
        ),
      ),
    );

    // 监听文本变化
    controller.addListener(_onTextChanged);

    ref.onDispose(() {
      _typingTimer?.cancel();
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
    final bool hasContent = controller.document.length > 1;

    if (hasContent && !_isTyping) {
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

  /// 发送输入状态（正在输入/结束输入）给聊天对方
  ///
  /// 通过 WebSocket 发送 HighMessage 类型 TYPING_STATUS，
  /// 前提是对方在线且房间成员已同步。
  void _sendTypingStatus(bool isTyping) {
    if (!ref.mounted) return;
    final room = ref.read(currentRoomProvider(roomId));
    if (room == null || room.peerId == null) return;

    final roomMembers = ref.read(roomMembersProvider(room.roomId!));

    // 成员未同步则跳过
    if (roomMembers.isEmpty) {
      log.debug('room ${room.roomId} members not synced, skip typing');
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
      log.debug('${peerMember.nickName} offline, skip typing: $isTyping');
      return;
    }

    final highMsg = HighMessage(
      type: HighMessageType.TYPING_STATUS,
      roomId: room.roomId,
      targetId: room.peerId,
      content: isTyping.toString(),
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    final bytes = ImPacketV5.encodeHighMessageFrame(highMsg);
    ref.read(wsControllerProvider.notifier).sendMessage(bytes);
  }

  /// 发送消息（从编辑器内容构建）
  ///
  /// 处理流程：
  /// 1. 获取当前房间和编辑器内容
  /// 2. 检查图片/文件上传状态，若有正在上传或失败则中止
  /// 3. 通过 DeltaProcessor 处理 Delta，提取图片、文件、纯文本、@提及、表情等
  /// 4. 分别发送图片、文件、表情或文本/富文本消息
  /// 5. 清空输入框并恢复焦点（桌面端）
  void sendMessage() {
    final room = ref.read(currentRoomProvider(roomId));
    if (room == null || state.document.isEmpty()) return;

    final uploadState = {
      ...ref.read(chatImageUploadControllerProvider.notifier).urlMap,
      ...ref.read(chatFileUploadControllerProvider.notifier).urlMap,
    };
    final processor = DeltaProcessor(state.document.toDelta(), uploadState);
    final mentionIds = processor.mentionedUserIds;

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
      for (final image in processor.images) {
        _doSend(
          type: MessageType.image,
          payload: const MessagePayload(content: '[image]'),
          attachments: [image],
          clearReplyAfterSend: false,
        );
      }
    }

    // --- 发送文件 ---
    if (processor.files.isNotEmpty) {
      _doSend(
        type: MessageType.file,
        payload: const MessagePayload(content: '[file]'),
        attachments: processor.files,
        clearReplyAfterSend: false,
      );
    }

    // --- 发送文本/富文本/表情 ---
    if (processor.plainText.isNotEmpty ||
        processor.mentionedUserIds.isNotEmpty) {
      final cleanDelta = processor.filteredDelta;
      // 如果 Delta 为空或仅包含换行且无 @提及，则忽略
      if (cleanDelta.length == 0 ||
          (cleanDelta.length == 1 &&
              cleanDelta.first.data == '\n' &&
              processor.mentionedUserIds.isEmpty)) {
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
        final isRich = processor.hasAttributes || mentionIds.isNotEmpty;
        _doSend(
          type: isRich ? MessageType.richText : MessageType.text,
          payload: isRich
              ? MessagePayload(
                  content: processor.plainText.characters.take(100).toString(),
                  quillDelta: jsonEncode(cleanDelta.toJson()),
                  mentions: mentionIds,
                )
              : MessagePayload(content: processor.plainText),
          clearReplyAfterSend: false,
        );
      }
    }

    // 4. 清空输入框
    clearInput();
    if (DeviceUtil.isRealDesktop()) {
      ref.read(chatFocusNodeProvider(room.roomId!)).requestFocus();
    }
  }

  /// 发送纯文本消息（Android 专用或外部调用）
  ///
  /// 若文本为单个表情符号，则作为 Emoji 消息发送。
  void sendPlainTextMessage(String text, {List<int>? mentionIds}) {
    final room = ref.read(currentRoomProvider(roomId));
    final content = text.trim();
    if (room == null || content.isEmpty) return;

    final isSingleEmoji =
        content.characters.length == 1 && _isEmoji(content.characters.first);

    _doSend(
      type: isSingleEmoji ? MessageType.emoji : MessageType.text,
      payload: MessagePayload(
        content: content,
        mentions: (mentionIds != null && mentionIds.isNotEmpty)
            ? mentionIds
            : null,
        emojiCode: isSingleEmoji ? content.characters.first : null,
      ),
    );
  }

  /// 发送卡片消息
  void sendCardMessage(CardPayload card) {
    final room = ref.read(currentRoomProvider(roomId));
    final title = card.displayTitle.trim();
    if (room == null || title.isEmpty) return;

    _doSend(
      type: MessageType.card,
      payload: MessagePayload(content: title, card: card),
    );
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

  /// 发送选中的图片（从文件选择器）
  ///
  /// 先上传图片，再逐个发送 Image 消息。
  Future<void> sendPickedImages(List<PlatformFile> files) async {
    if (files.isEmpty) return;

    final List<Attachment> uploadList = [];
    for (final file in files.where((f) => f.path != null)) {
      if (!UploadValidator.validateSingleFile(file)) continue;
      final imageSize = await _readImageSizeFromFile(file.path!);
      uploadList.add(
        Attachment(
          id: const Uuid().v4(),
          kind: 'IMAGE',
          url: file.path!,
          name: _basenameWithoutExtension(file.name),
          size: file.size,
          type: _imageMimeType(file.extension),
          width: imageSize.$1,
          height: imageSize.$2,
        ),
      );
    }
    if (uploadList.isEmpty) return;

    final uploader = ref.read(chatImageUploadControllerProvider.notifier);
    await uploader.uploadImages(uploadList);

    final urlMap = uploader.urlMap;
    final uploaded = uploadList
        .where((item) => urlMap[item.id] != null)
        .map((item) => item.copyWith(url: urlMap[item.id]))
        .toList();

    if (uploaded.isEmpty) return;

    for (var i = 0; i < uploaded.length; i++) {
      _doSend(
        type: MessageType.image,
        payload: const MessagePayload(content: '[image]'),
        attachments: [uploaded[i]],
        clearReplyAfterSend: i == uploaded.length - 1,
      );
    }
  }

  /// 发送选中的文件（从文件选择器）
  ///
  /// 先上传文件，再发送 File 消息（可包含多个附件）。
  Future<void> sendPickedFiles(List<PlatformFile> files) async {
    if (files.isEmpty) return;

    final List<Attachment> uploadList = [];
    for (final file in files.where((f) => f.path != null)) {
      if (!UploadValidator.validateSingleFile(file)) continue;
      uploadList.add(
        Attachment(
          id: const Uuid().v4(),
          kind: 'FILE',
          url: file.path!,
          name: _basenameWithoutExtension(file.name),
          size: file.size,
          type: file.extension ?? 'bin',
        ),
      );
    }
    if (uploadList.isEmpty) return;

    final uploader = ref.read(chatFileUploadControllerProvider.notifier);
    await uploader.uploadFiles(uploadList);

    final urlMap = uploader.urlMap;
    final uploaded = uploadList
        .where((item) => urlMap[item.id] != null)
        .map((item) => item.copyWith(url: urlMap[item.id]))
        .toList();

    if (uploaded.isEmpty) return;

    _doSend(
      type: MessageType.file,
      payload: const MessagePayload(content: '[file]'),
      attachments: uploaded,
    );
  }

  /// 纯文本变更处理（用于 Android 等平台，类似 _onTextChanged 的简化版）
  ///
  /// 更新输入状态、重置定时器，但不处理 @提及（因为 Android 使用单独机制）。
  void handlePlainTextChanged(String text) {
    final hasContent = text.trim().isNotEmpty;

    if (hasContent && !_isTyping) {
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
    required int duration,
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
      audioDuration: duration,
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
      final res = await DioClient().uploadFiles(
        '/file/uploadBatch',
        files: [file],
      );

      final rawList = res.data is Map ? res.data['data'] : res.data;
      if (rawList is! List || rawList.isEmpty) {
        // 上传失败，标记消息为 failed
        ref
            .read(chatMessagesProvider.notifier)
            .upsertMessage(
              localMsg.copyWith(deliveryStatus: DeliveryStatus.failed),
            );
        log.warning('voice upload failed: empty response');
        return;
      }

      final url = rawList.first.toString();

      // 3. 发送真正的语音消息
      _doSendVoice(
        clientMsgId: clientMsgId,
        url: url,
        duration: duration,
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
      log.error('语音消息发送异常: $e');
    }
  }

  /// 执行语音消息发送（通过 WebSocket）
  ///
  /// 更新本地消息（替换为真实 URL），发送 RoomMessage，并启动超时计时器。
  void _doSendVoice({
    required String clientMsgId,
    required String url,
    required int duration,
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
      audioDuration: duration,
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

    log.info('发送语音消息: $clientMsgId');
    final timeoutSeconds = _resolveSendTimeoutSeconds(
      type: MessageType.audio,
      attachments: attachments,
    );
    ref
        .read(wsControllerProvider.notifier)
        .sendMessage(
          ImPacketV5.encodeRoomMessageFrame(protoMsg),
          clientMsgId: clientMsgId,
          ackTimeout: Duration(seconds: timeoutSeconds),
        );
    ref.read(replyTargetControllerProvider.notifier).clear(roomId);
  }

  /// 判断字符是否为 Emoji（粗略判断）
  bool _isEmoji(String char) {
    final codePoint = char.runes.first;
    return (codePoint >= 0x1F300 && codePoint <= 0x1FAFF) ||
        (codePoint >= 0x2600 && codePoint <= 0x27BF);
  }

  /// 获取文件名（不含扩展名）
  String _basenameWithoutExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0) return fileName;
    return fileName.substring(0, dot);
  }

  /// 读取图片宽高
  Future<(int?, int?)> _readImageSizeFromFile(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final size = (image.width, image.height);
      image.dispose();
      codec.dispose();
      return size;
    } catch (_) {
      return (null, null);
    }
  }

  /// 根据扩展名获取图片 MIME 类型
  String _imageMimeType(String? extension) {
    final ext = extension?.toLowerCase();
    if (ext == null || ext.isEmpty) return 'image/jpeg';
    if (ext == 'jpg') return 'image/jpeg';
    return 'image/$ext';
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
        type == MessageType.video;
  }

  /// 通用发送消息方法
  ///
  /// 创建本地消息（sending 状态），发送 RoomMessage 到 WebSocket，并启动超时计时器。
  /// 支持附件、回复目标等。
  void _doSend({
    required MessageType type,
    required MessagePayload payload,
    List<Attachment>? attachments,
    bool clearReplyAfterSend = true,
  }) {
    final String clientMsgId = const Uuid().v4();
    final user = ref.read(authControllerProvider).value;
    if (user == null) {
      log.error('send failed: missing user');
      return;
    }
    final payloadWithReply = _withReplyTarget(type, payload);
    final payloadWithMedia = payloadWithReply.withMedia(
      type,
      attachments ?? const [],
    );
    final derivedAttachments = payloadWithMedia.mediaAttachments;

    final localMsg = ChatMessage(
      messageId: clientMsgId,
      clientMsgId: clientMsgId,
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
      clientMsgId: clientMsgId,
      roomId: roomId,
      senderId: user.userId,
      messageType: type,
      payload: payloadWithMedia,
      clientTimestamp: DateTime.now().millisecondsSinceEpoch,
    );

    log.info('发送消息[$type]: clientMsgId=$clientMsgId');
    final timeoutSeconds = _resolveSendTimeoutSeconds(
      type: type,
      attachments: derivedAttachments,
    );
    ref
        .read(wsControllerProvider.notifier)
        .sendMessage(
          ImPacketV5.encodeRoomMessageFrame(protoMsg),
          clientMsgId: clientMsgId,
          ackTimeout: Duration(seconds: timeoutSeconds),
        );
    if (clearReplyAfterSend) {
      ref.read(replyTargetControllerProvider.notifier).clear(roomId);
    }
  }
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
    );
  }

  /// 隐藏提及选择器
  void hide() {
    state = state.copyWith(isShowing: false);
  }

  /// 更新搜索文本（用户输入了更多字符）
  void updateSearch(String text) {
    state = state.copyWith(searchText: text);
  }
}

/// @提及状态数据类
///
/// 包含是否显示、光标位置、搜索关键字、@符号偏移量（用于定位）。
class MentionStateData {
  final bool isShowing;
  final int cursorPosition;
  final String searchText;
  final Offset? atSymbolOffset; // @ 符号在屏幕上的偏移，用于锚定弹出层

  MentionStateData({
    this.isShowing = false,
    this.cursorPosition = 0,
    this.searchText = '',
    this.atSymbolOffset,
  });

  MentionStateData copyWith({
    bool? isShowing,
    int? cursorPosition,
    String? searchText,
    Offset? atSymbolOffset,
  }) {
    return MentionStateData(
      isShowing: isShowing ?? this.isShowing,
      cursorPosition: cursorPosition ?? this.cursorPosition,
      searchText: searchText ?? this.searchText,
      atSymbolOffset: atSymbolOffset ?? this.atSymbolOffset,
    );
  }
}
