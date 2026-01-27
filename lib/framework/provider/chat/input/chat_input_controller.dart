import 'dart:async';
import 'dart:convert';

import 'package:anoxia/framework/protocol/message/Attachment.dart';
import 'package:anoxia/framework/provider/chat/input/DeltaProcessor.dart';
import 'package:anoxia/framework/provider/chat/input/files/chat_file_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/images/chat_image_upload_controller.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:anoxia/framework/services/room_list_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../logs/talker.dart';

part 'chat_input_controller.g.dart';

@Riverpod(keepAlive: true)
class ChatInputController extends _$ChatInputController {
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  QuillController build(String roomId) {
    final controller = QuillController.basic();

    // 监听文本变化处理“正在输入”逻辑
    controller.addListener(_onTextChanged);

    ref.onDispose(() {
      _typingTimer?.cancel();
      controller.dispose();
    });

    return controller;
  }

  /// 监听文本变化处理“正在输入”逻辑
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
  }

  /// 发送正在输入状态
  void _sendTypingStatus(bool isTyping) {
    if (!ref.mounted) return;
    final room = ref.read(activeRoomProvider);
    if (room == null) return;

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
    if (room == null || state.document.length <= 1) return;

    final uploadState = {
      ...ref.read(chatImageUploadControllerProvider),
      ...ref.read(chatFileUploadControllerProvider),
    };
    final processor = DeltaProcessor(state.document.toDelta(), uploadState);

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
        type: "IMAGE",
        payload: {"content": "[图片]"},
        attachments: processor.images,
      );
    }
    // 发送文件
    if (processor.files.isNotEmpty) {
      _doSend(
        type: "FILE",
        payload: {"content": "[文件]"},
        attachments: processor.files,
      );
    }
    // 发送文字 (包含富文本样式)
    if (processor.plainText.isNotEmpty) {
      final isRich = processor.hasAttributes;
      _doSend(
        type: isRich ? "QUILL" : "TEXT",
        payload: isRich
            ? {
                "content": processor.plainText.characters.take(100).toString(),
                "quillDelta": jsonEncode(processor.textOnlyDelta.toJson()),
              }
            : {"content": processor.plainText},
      );
    }
    // 4. 清空输入
    clearInput();
    ref.read(chatFocusNodeProvider(room.roomId!)).requestFocus();
  }

  void clearInput() {
    state.clear();
    _isTyping = false;
  }

  // 统一的内部发送方法
  void _doSend({
    required String type,
    required Map<String, dynamic> payload,
    List<Attachment>? attachments,
  }) {
    final room = ref.read(activeRoomProvider)!;
    final messageData = {
      "topic": "MESSAGE",
      "data": {
        "messageId": "msg-${const Uuid().v4()}",
        "roomId": room.roomId,
        "targetId": room.peerId,
        "type": type,
        "payload": payload,
        "attachments": attachments?.map((e) => e.toJson()).toList() ?? [],
      },
    };

    log.info("🚀 发送消息 [$type]: ${jsonEncode(messageData)}");
    ref
        .read(wsControllerProvider.notifier)
        .sendMessage(jsonEncode(messageData));
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
