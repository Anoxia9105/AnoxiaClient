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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final activeId = ref.read(activeRoomIdProvider);

    // 调用 WS 发送逻辑
    ref.read(wsControllerProvider.notifier).sendMessage("""
{
  "topic":"MESSAGE",
  "data":{
    "messageId": "msg-${DateTime.now().millisecondsSinceEpoch}",
    "roomId": "$activeId",
    "targetId": "2",
    "type": "TEXT",
    "payload": { "content": "$text" }
  }
}
                      """);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(controller: _controller /* ...decoration... */),
            ),
            IconButton(onPressed: _handleSend, icon: const Icon(Icons.send)),
          ],
        ),
      ),
    );
  }
}
