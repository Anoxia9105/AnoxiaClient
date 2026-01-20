import 'package:anoxia/framework/provider/call/call_window_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../framework/domain/ChatRoomVO.dart';
import '../../../../framework/protocol/message/HighMessage.dart';
import '../../../../framework/provider/theme/theme_controller.dart';
import '../../../../framework/services/high_message_service.dart';
import '../../../../framework/services/room_list_service.dart';

class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback onTap;

  const ChatAppBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeId = ref.watch(activeRoomIdProvider);
    final roomListAsync = ref.watch(roomListServiceProvider);
    final isTyping = ref.watch(
      highMessageServiceProvider.select(
        (state) =>
            state[activeId]?[HighMessageType.TYPING_STATUS]?.content == "true",
      ),
    );

    final currentRoom = roomListAsync.value?.firstWhere(
      (r) => r.roomId == activeId,
      orElse: () => ChatRoomVO(),
    );

    return AppBar(
      actionsPadding: EdgeInsets.all(4),
      shape: Border(
        bottom: BorderSide(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          width: 1.0, // 边框粗细
        ),
      ),
      title: roomListAsync.when(
        data: (rooms) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentRoom?.roomName ?? '对话详情',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isTyping)
                Text(
                  "对方正在输入...",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
            ],
          );
        },
        loading: () => const Text("正在连接..."),
        error: (_, __) => const Text("会话已断开"),
      ),
      actions: [
        IconButton(
          onPressed: () {
            ref
                .read(callWindowControllerProvider.notifier)
                .openCallWindow(
                  title: currentRoom?.roomName ?? '',
                  themeIndex: ref.read(themeIndexProvider),
                  roomId: currentRoom?.roomId ?? ''
                );
          },
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedCall02, size: 20),
        ),
        IconButton(
          onPressed: () {},
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedVideo02, size: 20),
        ),
        IconButton(
          onPressed: onTap,
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedMore02, size: 20),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
