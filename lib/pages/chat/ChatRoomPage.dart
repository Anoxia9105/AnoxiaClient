import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notepadclient/framework/protocol/message/RoomMessage.dart';

import '../../framework/services/room_message_service.dart';

class ChatRoomPage extends ConsumerWidget {
  final String roomId;

  const ChatRoomPage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 核心：使用 select 只监听当前房间的消息列表
    // 这样当其他房间收到消息时，这个页面不会触发无效重绘
    final messages = ref.watch(
      chatMessagesProvider.select((map) => map[roomId] ?? []),
    );


    return Scaffold(
      appBar: AppBar(title: Text("房间: $roomId")),
      body: Column(
        children: [
          // 消息列表区
          Expanded(
            child: ListView.builder(
              reverse: true, // 习惯上 IM 列表会反转，新的在下面
              itemCount: messages.length,
              itemBuilder: (context, index) {
                // 因为 reverse 了，所以取倒序索引，或者根据你存的顺序处理
                final msg = messages[messages.length - 1 - index];
                return MessageItem(message: msg); // 你的消息组件
              },
            ),
          ),
          // 输入框区
          TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: '外边框模式',
              prefixIcon: Icon(Icons.person),
            ),
          ),
        ],
      ),
    );
  }

  Widget MessageItem({required RoomMessage message}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("${message.senderId}:${message.targetId} "),
        Text("${message.type}:${message.payload?.content} "),
      ],
    );
  }
}
