import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../framework/provider/ws/ws_controller.dart';
import '../../../../framework/services/room_list_service.dart';

class ChatInputField extends ConsumerStatefulWidget {
  const ChatInputField({super.key});

  @override
  ConsumerState<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends ConsumerState<ChatInputField> {
  late TextEditingController _controller;
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    // 监听输入框变化
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final room = ref.read(activeRoomProvider);
    if (room == null) return;

    ref
        .read(wsControllerProvider.notifier)
        .sendMessage(
          jsonEncode({
            "topic": "MESSAGE",
            "data": {
              "messageId": "msg-${DateTime.now().millisecondsSinceEpoch}",
              "roomId": room.roomId,
              "targetId": room.peerId,
              "type": "TEXT",
              "payload": {"content": text},
            },
          }),
        );

    // 发送完立即重置输入状态
    _isTyping = false;
    _sendTypingStatus(false);
    _controller.clear();
  }

  void _onTextChanged() {
    final room = ref.read(activeRoomProvider);
    if (room == null) return;

    // 只有单聊需要发送正在输入状态
    if (room.roomType != "0") return;

    if (!_isTyping && _controller.text.isNotEmpty) {
      _isTyping = true;
      _sendTypingStatus(true);
    }

    // 防抖逻辑：停止打字 2 秒后发送结束状态
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        _sendTypingStatus(false);
      }
    });
  }

  void _sendTypingStatus(bool isTyping) {
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(hintText: "输入消息..."),
                onSubmitted: (_) => _handleSend(), // 支持回车发送
              ),
            ),
            IconButton(onPressed: _handleSend, icon: const Icon(Icons.send)),
          ],
        ),
      ),
    );
  }
}
