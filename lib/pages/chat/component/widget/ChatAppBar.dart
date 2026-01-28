import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/domain/ChatRoomMemberVO.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../framework/domain/ChatRoomVO.dart';
import '../../../../framework/protocol/message/HighMessage.dart';
import '../../../../framework/provider/chat/message/high_message_service.dart';
import '../../../../framework/provider/chat/room/room_list_service.dart';
import '../../../../framework/provider/theme/theme_controller.dart';

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

    final currentUser = ref.watch(authControllerProvider).value;
    final List<ChatRoomMemberVO> rawMembers = ref
        .read(roomMemberServiceProvider.notifier)
        .getMembersByRoom(activeId ?? '');
    final member = rawMembers.map((m) {
      if (m.userId == currentUser?.userId) {
        // 使用 copyWith 产生一个新对象，名字后面加上 (我)
        return m.copyWith(nickName: "${m.nickName ?? '未知用户'} (我)");
      }
      return m;
    }).toList();
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
        Container(
          margin: EdgeInsets.all(4),
          child: VerticalDivider(indent: 4, endIndent: 4),
        ),
        IconButton(
          onPressed: () {},
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedSearch01, size: 20),
        ),
        Builder(
          builder: (context) {
            return InkWell(
              onTap: () => Toast.showWidget(
                context,
                child: Material(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    constraints: BoxConstraints(maxHeight: 400),
                    width: 200,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            "人员列表 (${member.length})",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Divider(height: 1),
                        Flexible(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: member.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1, indent: 56),
                            itemBuilder: (context, index) {
                              final m = member[index];
                              return ListTile(
                                dense: true,
                                leading: AvatarWidget(
                                  url: m.avatar,
                                  name: m.nickName,
                                  size: 30,
                                  status: m.onlineStatus ?? false
                                      ? AvatarStatus.online
                                      : AvatarStatus.offline,
                                ),
                                title: Text(m.nickName ?? '未知用户'),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                direction: PreferDirection.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(8),
              child: Ink(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedUserMultiple02,
                      size: 20,
                    ),
                    Text("${member.length}"),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 抽离出来的搜索方法
  void _handleSearch() {
    print("开启搜索逻辑...");
    // 这里写你点击搜索按钮后要执行的代码
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
