import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/domain/ChatRoomMemberVO.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/pages/chat/component/widget/SearchContextPage.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../framework/domain/ChatRoomVO.dart';
import '../../../../framework/protocol/message/HighMessage.dart';
import '../../../../framework/provider/chat/message/high_message_service.dart';
import '../../../../framework/provider/chat/room/room_list_service.dart';
import '../../../../framework/provider/theme/theme_controller.dart';
import 'AddMemberDialogWidget.dart';

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
    final List<ChatRoomMemberVO> rawMembers = ref.watch(
      roomMemberServiceProvider.select((state) => state[activeId ?? ''] ?? []),
    );

    final member = rawMembers.map((m) {
      if (m.userId == currentUser?.userId) {
        // 使用 copyWith 产生一个新对象，名字后面加上 (我)
        return m.copyWith(
          nickName: "${m.nickName ?? 'appbar_unknown_user'.tr()} (我)",
        );
      }
      return m;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: AppBar(
        actionsPadding: EdgeInsets.all(4),
        title: roomListAsync.when(
          data: (rooms) {
            if (isTyping) {
              return Text(
                'appbar_user_typing'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              );
            }
            return Text(
              currentRoom?.roomName ?? 'appbar_conversation_detail'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            );
          },
          loading: () => Text('appbar_connecting'.tr()),
          error: (_, _) => Text('appbar_connection_lost'.tr()),
        ),
        actions: [
          IconButton(
            tooltip: 'appbar_start_meeting'.tr(),
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
            tooltip: 'appbar_search_in_chat'.tr(),
            onPressed: () {
              _showSearchDialog(context, ref, activeId ?? '');
            },
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              size: 20,
            ),
          ),
          if (currentRoom != null && currentRoom.roomType == 1)
            IconButton(
              tooltip: 'appbar_add_member'.tr(),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddMemberDialogWidget(
                    roomId: currentRoom.roomId!,
                    roomName: currentRoom.roomName!,
                  ),
                );
              },
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedAddTeam,
                size: 20,
              ),
            ),
          Builder(
            builder: (context) {
              return Tooltip(
                message: 'appbar_member_list'.tr(),
                child: InkWell(
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
                                '${'appbar_member_list'.tr()} (${member.length})',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Divider(height: 1),
                            Flexible(
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
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
                          size: 18,
                        ),
                        Text("${member.length}"),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 显示搜索对话框
  void _showSearchDialog(BuildContext context, WidgetRef ref, String roomId) {
    final currentRoom = ref.read(roomListServiceProvider).value?.firstWhere(
      (r) => r.roomId == roomId,
      orElse: () => ChatRoomVO(),
    );
    final roomName = currentRoom?.roomName ?? 'appbar_conversation_detail'.tr();
    
    final isDesktop = DeviceUtil.isRealDesktop();
    final dialogWidth = isDesktop ? 1000.0 : 400.0;
    final dialogHeight = isDesktop ? 750.0 : 600.0;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: SearchContextPage(
            roomId: roomId,
            roomName: roomName,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
