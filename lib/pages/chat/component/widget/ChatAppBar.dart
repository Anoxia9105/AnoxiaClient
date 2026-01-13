import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../framework/domain/ChatRoomVO.dart';
import '../../../../framework/protocol/message/HighMessage.dart';
import '../../../../framework/services/high_message_service.dart';
import '../../../../framework/services/room_list_service.dart';

class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ChatAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeId = ref.watch(activeRoomIdProvider);
    final roomListAsync = ref.watch(roomListServiceProvider);
    final isTyping = ref.watch(highMessageServiceProvider.select((state) =>
    state[activeId]?[HighMessageType.TYPING_STATUS]?.content == "true"));

    return AppBar(
      title: roomListAsync.when(
        data: (rooms) {
          final currentRoom = rooms.firstWhere((r) => r.roomId == activeId, orElse: () => ChatRoomVO());
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(currentRoom.roomName ?? '对话详情', style: const TextStyle(fontSize: 16)),
              if (isTyping)
                Text("对方正在输入...", style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColor)),
            ],
          );
        },
        loading: () => const Text("正在连接..."),
        error: (_, __) => const Text("会话已断开"),
      ),
      actions: [ /* 通话按钮等 */ ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}