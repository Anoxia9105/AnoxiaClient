import 'dart:async';
import 'dart:convert';

import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:anoxia/framework/services/room_list_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../logs/talker.dart';

part 'chat_input_controller.g.dart';

@riverpod
class ChatInputController extends _$ChatInputController {
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  QuillController build(String roomId) {
    ref.keepAlive();
    final controller = QuillController.basic();

    // 监听文本变化处理“正在输入”逻辑
    controller.addListener(_onTextChanged);

    ref.onDispose(() {
      _typingTimer?.cancel();
      controller.dispose();
    });

    return controller;
  }

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

  void sendMessage() {
    final room = ref.read(activeRoomProvider);
    if (room == null) return;

    final doc = state.document;

    final List<Map<String, dynamic>> messageParts = [];

    for (final node in doc.root.children) {
      if (node is Embed) {
        // 图片
        final data = jsonDecode(node.value.data) as Map<String, dynamic>;
        if (node.value.type == BlockEmbed.imageType) {
          messageParts.add({
            "type": "IMAGE",
            "payload": {"content": "[图片]"},
            "attachments": {"url": data["url"]},
          });
        }
      } else if (node is Line) {
        // 文本
        final text = node.toPlainText().trim();
        if (text.isNotEmpty) {
          messageParts.add({
            "type": "TEXT",
            "payload": {"content": text},
          });
        }
      }
    }

    if (messageParts.isEmpty) {
      Toast.showToast("不能发送空消息", type: ToastType.warning);
      return;
    }

    // 发送每一条消息
    for (var part in messageParts) {
      // ref
      //     .read(wsControllerProvider.notifier)
      //     .sendMessage(
      //       jsonEncode({
      //         "topic": "MESSAGE",
      //         "data": {
      //           "messageId": "msg-${DateTime.now().millisecondsSinceEpoch}",
      //           "roomId": room.roomId,
      //           "targetId": room.peerId,
      //           "type": part["type"], // TEXT 或 IMAGE
      //           "payload": part["payload"],
      //         },
      //       }),
      //     );
      log.info(
        jsonEncode({
          "topic": "MESSAGE",
          "data": {
            "messageId": "msg-${DateTime.now().millisecondsSinceEpoch}",
            "roomId": room.roomId,
            "targetId": room.peerId,
            "type": part["type"],
            "payload": part["payload"],
            "attachments": part["attachments"],
          },
        }),
      );
    }

    // 清空输入
    clearInput();
    ref.read(chatFocusNodeProvider(room.roomId!)).requestFocus();
  }

  void clearInput() {
    state.clear();
    _isTyping = false;
  }
}

@riverpod
FocusNode chatFocusNode(Ref ref, String roomId) {
  final node = FocusNode();
  ref.onDispose(() => node.dispose());
  return node;
}
