import 'package:anoxia/common/widgets/Toast.dart';
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
  const ChatAppBar({super.key});

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
      title: roomListAsync.when(
        data: (rooms) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                currentRoom?.roomName ?? '对话详情',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "对方正在输入...",
                style: TextStyle(
                  fontSize: 12,
                  color: isTyping
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                ),
              ),
            ],
          );
        },
        loading: () => const Text("正在连接..."),
        error: (_, _) => const Text("会话已断开"),
      ),
      actions: [
        IconButton(
          onPressed: () {
            ref
                .read(callWindowControllerProvider.notifier)
                .openCallWindow(
                  title: currentRoom?.roomName ?? '',
                  themeIndex: ref.read(themeIndexProvider),
                  roomId: currentRoom?.roomId ?? '',
                );
          },
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedCall02, size: 20),
        ),
        IconButton(
          onPressed: () {},
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedVideo02, size: 20),
        ),
        Builder(
          builder: (context) {
            return IconButton(
              onPressed: () {
                Toast.showWidget(
                  context,
                  child: Container(
                    width: 100,
                    color: Colors.white,
                    height: 100,
                    child: Text("data"),
                  ),
                );
              },
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedMore02,
                size: 20,
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
