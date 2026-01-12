import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notepadclient/framework/protocol/message/RoomMessage.dart';
import 'package:notepadclient/framework/provider/ws/ws_controller.dart';

import '../../../framework/protocol/message/HighMessage.dart';
import '../../../framework/services/high_message_service.dart';
import '../../../framework/services/room_message_service.dart';

class ChatRoomDetail extends ConsumerStatefulWidget {
  final String roomId;

  const ChatRoomDetail({super.key, required this.roomId});

  @override
  ConsumerState<ChatRoomDetail> createState() => _ChatRoomDetailState();
}

class _ChatRoomDetailState extends ConsumerState<ChatRoomDetail> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0, // 因为 reverse = true
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(
      chatMessagesProvider.select((map) => map[widget.roomId] ?? []),
    );

    // 💡 观察最新的高优消息
    final highMsg = ref.watch(highMessageServiceProvider);
    final roomStatus = highMsg[widget.roomId];
    final isTyping =
        roomStatus?[HighMessageType.TYPING_STATUS]?.content == "true";
    final hasCall = roomStatus?[HighMessageType.CALL_INVITE] != null;

    _scrollToBottom();

    return Scaffold(
      appBar: AppBar(
        title: Text("房间：${widget.roomId}--${isTyping ? "输入中..." : ""}"),
        elevation: 0,
        centerTitle: true,
      ),

      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[messages.length - 1 - index];
                return MessageBubble(message: msg);
              },
            ),
          ),

          // 输入框区域
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "输入消息…",
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.15),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;

                      ref.read(wsControllerProvider.notifier).sendMessage("""
{
  "topic":"MESSAGE",
  "data":{
    "messageId": "msg-${DateTime.now().millisecondsSinceEpoch}",
    "roomId": "${widget.roomId}",
    "targetId": "2",
    "type": "TEXT",
    "payload": { "content": "$text" }
  }
}
                      """);

                      _controller.clear();
                      _scrollToBottom();
                    },
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final RoomMessage message;

  const MessageBubble({super.key, required this.message});

  bool get isMe => message.senderId == 1; // TODO: 替换成当前用户 ID

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe
        ? Theme.of(context).colorScheme.primary.withOpacity(0.85)
        : Colors.grey.withOpacity(0.2);

    final textColor = isMe ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(radius: 16, child: Text("${message.senderId}")),
          if (!isMe) const SizedBox(width: 8),

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.payload?.content ?? "",
                style: TextStyle(color: textColor, fontSize: 15),
              ),
            ),
          ),

          if (isMe) const SizedBox(width: 8),
          if (isMe)
            CircleAvatar(radius: 16, child: Text("${message.senderId}")),
        ],
      ),
    );
  }
}
