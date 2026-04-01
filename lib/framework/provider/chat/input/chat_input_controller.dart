import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:anoxia/framework/domain/ChatMessage.dart';
import 'package:anoxia/framework/protocol/message/Attachment.dart';
import 'package:anoxia/framework/protocol/message/MessageEunm.dart';
import 'package:anoxia/framework/protocol/message/MessagePayload.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/input/DeltaProcessor.dart';
import 'package:anoxia/framework/provider/chat/input/files/chat_file_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/images/chat_image_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../logs/talker.dart';
import '../room/room_member_service.dart';

part 'chat_input_controller.g.dart';

@Riverpod(keepAlive: true)
class ChatInputController extends _$ChatInputController {
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  QuillController build(String roomId) {
    // 提前定义 controller 变量，以便在闭包中使用
    late QuillController controller;

    controller = QuillController.basic(
      config: QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(
          enableExternalRichPaste: false, // 禁止富文本，防止格式错乱

          // --- 核心修改：对接粘贴板图片 ---
          onImagePaste: (Uint8List imageBytes) async {
            log.info("检测到图片粘贴，大小: ${imageBytes.lengthInBytes} 字节");

            // 调用 ChatImageUploadController 处理粘贴
            // 逻辑：存临时文件 -> 插入预览 -> 后台静默上传
            await ref.read(chatImageUploadControllerProvider.notifier)
                .handlePastedImage(controller, imageBytes);

            // 返回 null，表示“我已经手动处理了插入，Quill 你不用再管了”
            return null;
          },

          // 处理纯文本粘贴（例如过滤敏感词）
          onPlainTextPaste: (String plainText) async {
            log.info("检测到TEXT粘贴$plainText");
            return plainText;
          },
        ),
      ),
    );

    // 监听文本变化处理“正在输入”逻辑
    controller.addListener(_onTextChanged);

    ref.onDispose(() {
      _typingTimer?.cancel();
      controller.dispose();
    });

    return controller;
  }


  /// 监听文本变化处理
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

    // 延迟执行，避免在 notifyListeners 期间修改 provider
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!ref.mounted) return;

      final selection = controller.selection;

      if (selection.baseOffset > 0) {
        final plainText = controller.document.toPlainText();
        final cursorPosition = selection.baseOffset;

        // 检查光标前的字符是否是 @
        if (cursorPosition <= plainText.length &&
            plainText[cursorPosition - 1] == '@') {
          ref.read(mentionStateProvider.notifier).show(cursorPosition, '');
          return;
        }

        // 如果已经在 @ 状态,更新搜索文本
        final mentionState = ref.read(mentionStateProvider);
        if (mentionState.isShowing) {
          // 检查光标是否回退到@符号之前（用户删除了@或退格到@之前）
          if (cursorPosition < mentionState.cursorPosition) {
            ref.read(mentionStateProvider.notifier).hide();
            return;
          }

          // 检查@符号位置是否还是@符号
          if (mentionState.cursorPosition > 0 &&
              mentionState.cursorPosition - 1 < plainText.length &&
              plainText[mentionState.cursorPosition - 1] != '@') {
            // @符号被删除了
            ref.read(mentionStateProvider.notifier).hide();
            return;
          }

          // 提取 @ 后的文本
          final textAfterAt = plainText.substring(
            mentionState.cursorPosition,
            cursorPosition.clamp(mentionState.cursorPosition, plainText.length),
          );

          // 如果遇到空格或换行,关闭弹窗
          if (textAfterAt.contains(' ') || textAfterAt.contains('\n')) {
            ref.read(mentionStateProvider.notifier).hide();
          } else {
            ref.read(mentionStateProvider.notifier).updateSearch(textAfterAt);
          }
        }
      } else {
        // 光标在开头，如果弹窗正在显示则关闭
        final mentionState = ref.read(mentionStateProvider);
        if (mentionState.isShowing) {
          ref.read(mentionStateProvider.notifier).hide();
        }
      }
    });
  }

  /// 发送正在输入状态
  void _sendTypingStatus(bool isTyping) {
    if (!ref.mounted) return;
    final room = ref.read(activeRoomProvider);
    //房间或者接收者是空的不发送  （群聊不发）
    if (room == null || room.peerId == null) return;

    //用户在线发送 TYPING_STATUS 不在线不发送
    final roomMembers = ref
        .read(roomMembersProvider(room.roomId!));

    // 4.1 成员列表为空（未同步），不发送
    if (roomMembers.isEmpty) {
      log.debug("房间${room.roomId}成员列表未同步，暂不发送typing状态");
      return;
    }

    // 根据peerId查找对方成员
    final peerMember = roomMembers.firstWhereOrNull(
      (member) => member.userId == room.peerId,
    );

    if (peerMember == null) return;

    // 找不到对方成员 或 对方离线，不发送
    if (peerMember.onlineStatus != true) {
      
      log.debug("${peerMember.nickName}离线，不发送typing（isTyping: $isTyping）");
      return;
    }

    final msg = {
      "topic": "HIGH_FREQUENCY",
      "data": {
        "targetId": room.peerId,
        "roomId": room.roomId,
        "type": "TYPING_STATUS",
        "content": isTyping.toString(),
      },
    };

    ref.read(wsControllerProvider.notifier).sendMessage(jsonEncode(msg));
  }

  /// 发送消息
  void sendMessage() {
    final room = ref.read(activeRoomProvider);
    if (room == null || state.document.isEmpty()) return;

    final uploadState = {
      ...ref.read(chatImageUploadControllerProvider),
      ...ref.read(chatFileUploadControllerProvider),
    };
    final processor = DeltaProcessor(state.document.toDelta(), uploadState);
    final mentionIds = processor.mentionedUserIds;
    // 拦截：正在上传中
    if (ref.read(isUploadingProvider)) {
      return;
    }
    // 拦截：检查是否有失败/未上传的文件
    if (!processor.isAllUploaded) {
      return;
    }
    // --- 策略：拆分发送 ---
    if (processor.images.isNotEmpty) {
      _doSend(
        type: MessageType.image,
        payload: MessagePayload(content: "[图片]"),
        attachments: processor.images,
      );
    }
    // 发送文件
    if (processor.files.isNotEmpty) {
      _doSend(
        type: MessageType.file,
        payload: MessagePayload(content: "[文件]"),
        attachments: processor.files,
      );
    }
    // 发送文字/Emoji (包含富文本样式)
    if (processor.plainText.isNotEmpty ||
        processor.mentionedUserIds.isNotEmpty) {
      final cleanDelta = processor.filteredDelta;
      // 再次检查清理后的 Delta 是否有效（避免只发了一个换行符）
      if (cleanDelta.length == 0 ||
          (cleanDelta.length == 1 &&
              cleanDelta.first.data == '\n' &&
              processor.mentionedUserIds.isEmpty)) {
        // 如果清理完图片后只剩空换行，且没有 @，则不发送
        return;
      }

      if (processor.isSingleEmoji) {
        _doSend(
          type: MessageType.text,
          payload: MessagePayload(
            content: processor.plainText, // emoji内容
            emojiCode: processor.plainText.characters.first,
          ),
        );
      } else {
        final isRich = processor.hasAttributes || mentionIds.isNotEmpty;
        _doSend(
          type: isRich ? MessageType.quill : MessageType.text,
          payload: isRich
              ? MessagePayload(
                  content: processor.plainText.characters.take(100).toString(),
                  quillDelta: jsonEncode(cleanDelta.toJson()),
                  mentions: mentionIds,
                )
              : MessagePayload(content: processor.plainText),
        );
      }
    }
    // 4. 清空输入
    clearInput();
    ref.read(chatFocusNodeProvider(room.roomId!)).requestFocus();
  }

  void clearInput() {
    state.clear();
    _isTyping = false;
    ref.read(mentionStateProvider.notifier).hide();
  }

  // 统一的内部发送方法
  void _doSend({
    required MessageType type,
    required MessagePayload payload,
    List<Attachment>? attachments,
  }) {
    final room = ref.read(activeRoomProvider)!;
    final String clientMsgId = const Uuid().v4();
    final user = ref.read(authControllerProvider).value;
    if (room == null || user == null) {
      log.error("发送失败: 房间或用户信息缺失");
      return;
    }

    final localMsg = ChatMessage(
      messageId: clientMsgId,
      clientMsgId: clientMsgId,
      roomId: room.roomId,
      senderId: user.userId,
      messageType: type,
      content: payload.content ?? '',
      payload: payload,
      attachments: attachments ?? [],
      timestamp: DateTime.now().millisecondsSinceEpoch,
      deliveryStatus: DeliveryStatus.sending,
      seq: 0,
    );

    ref.read(chatMessagesProvider.notifier).upsertMessage(localMsg);

    final messageData = {
      "topic": "MESSAGE",
      "data": {
        "messageId": clientMsgId,
        "clientMsgId": clientMsgId,
        "roomId": room.roomId,
        "targetId": room.peerId,
        "type": type.name,
        "payload": payload.toJson(),
        "attachments": attachments?.map((e) => e.toJson()).toList() ?? [],
      },
    };

    log.info("🚀 发送消息 [$type]: ${jsonEncode(messageData)}");
    ref
        .read(wsControllerProvider.notifier)
        .sendMessage(jsonEncode(messageData));
    // 4. 设置超时处理
    Timer(const Duration(seconds: 10), () {
      ref
          .read(chatMessagesProvider.notifier)
          .handleTimeout(room.roomId!, clientMsgId);
    });
  }
}

/// 聊天输入框焦点
@riverpod
FocusNode chatFocusNode(Ref ref, String roomId) {
  final node = FocusNode();
  ref.onDispose(() => node.dispose());
  return node;
}

/// 上传状态（UI 用）
@Riverpod(keepAlive: true)
class IsUploading extends _$IsUploading {
  @override
  bool build() {
    return false;
  }

  void start() => state = true;

  void stop() => state = false;
}

// 在 chat_input_controller.dart 中添加
@Riverpod(keepAlive: true)
class MentionState extends _$MentionState {
  @override
  MentionStateData build() => MentionStateData();

  void show(int cursorPosition, String searchText, {Offset? atSymbolOffset}) {
    state = state.copyWith(
      isShowing: true,
      cursorPosition: cursorPosition,
      searchText: searchText,
      atSymbolOffset: atSymbolOffset,
    );
  }

  void hide() {
    state = state.copyWith(isShowing: false);
  }

  void updateSearch(String text) {
    state = state.copyWith(searchText: text);
  }
}

class MentionStateData {
  final bool isShowing;
  final int cursorPosition;
  final String searchText;
  final Offset? atSymbolOffset; // @ 符号在屏幕上的位置

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
