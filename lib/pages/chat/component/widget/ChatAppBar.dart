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

    final currentRoom = ref.read(activeRoomProvider);

    final currentUser = ref.watch(authControllerProvider).value;

    final members = ref.watch(
      roomMemberServiceProvider.select((state) {
        final map = state[activeId ?? ''];
        if (map == null) return const <ChatRoomMemberVO>[];

        final list = map.values.toList();

        if (currentUser?.userId == null) return list;

        return list.map((m) {
          if (m.userId == currentUser?.userId) {
            return m.copyWith(
              nickName: "${m.nickName ?? 'appbar_unknown_user'.tr()} (我)",
            );
          }
          return m;
        }).toList();
      }),
    );

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
          // 判断房间状态，如果已解散(status=3)则禁用大部分功能
          if (currentRoom?.roomStatus != 3)
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
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedCall02,
                size: 20,
              ),
            ),
          if (currentRoom?.roomStatus != 3)
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
          if (currentRoom != null &&
              currentRoom.roomType == 1 &&
              currentRoom.roomStatus != 3)
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
          // 禁言按钮（只有管理员在群聊中可见，且房间未解散）
          if (currentRoom != null &&
              currentRoom.roomType == 1 &&
              currentRoom.roomStatus != 3)
            Builder(
              builder: (context) {
                // 检查当前用户是否是管理员
                final isAdmin = members.any(
                  (m) => m.userId == currentUser?.userId && m.roleId == 0,
                );

                if (!isAdmin) return const SizedBox.shrink();

                final isMuted = currentRoom.roomStatus == 1;

                return IconButton(
                  tooltip: isMuted ? '解除禁言' : '全员禁言',
                  onPressed: () {
                    _handleMuteRoom(
                      context,
                      ref,
                      currentRoom.roomId ?? '',
                      !isMuted,
                    );
                  },
                  icon: HugeIcon(
                    icon: isMuted
                        ? HugeIcons.strokeRoundedVolumeMute02
                        : HugeIcons.strokeRoundedVolumeOff,
                    size: 20,
                    color: isMuted
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                );
              },
            ),
          if (currentRoom?.roomStatus != 3)
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
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
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
                                  '${'appbar_member_list'.tr()} (${members.length})',
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
                                  itemCount: members.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(height: 1, indent: 56),
                                  itemBuilder: (context, index) {
                                    final m = members[index];
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
                                      trailing: Builder(
                                        builder: (context) {
                                          // 1. 获取当前登录用户的 ID
                                          final currentUserId = ref
                                              .read(authControllerProvider)
                                              .value
                                              ?.userId;

                                          // 2. 获取当前登录用户在成员列表中的角色 (判断“我”是不是管理员)

                                          final isIMeAdmin = members.any(
                                            (m) =>
                                                m.userId == currentUserId &&
                                                m.roleId == 0,
                                          );

                                          // 3. 逻辑判断
                                          if (m.roleId == 0) {
                                            return Text(
                                              "管理员",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                            );
                                          }

                                          // 如果“我”是管理员，且当前行不是“我”自己，则显示踢出按钮
                                          if (isIMeAdmin &&
                                              m.userId != currentUserId) {
                                            return IconButton(
                                              icon: HugeIcon(
                                                icon: HugeIcons
                                                    .strokeRoundedUserRoadside,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                _handleKickMember(
                                                  context,
                                                  ref,
                                                  currentRoom?.roomId ?? '',
                                                  m.userId ?? 0,
                                                  m.nickName ?? '未知用户',
                                                );
                                              },
                                              tooltip: '踢出成员',
                                            );
                                          }
                                          // 其他情况（普通成员看别人，或者普通成员看自己）什么都不显示
                                          return const SizedBox.shrink();
                                        },
                                      ),
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
                          Text("${members.length}"),
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
    final currentRoom = ref
        .read(roomListServiceProvider)
        .value
        ?.firstWhere((r) => r.roomId == roomId, orElse: () => ChatRoomVO());
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
          child: SearchContextPage(roomId: roomId, roomName: roomName),
        ),
      ),
    );
  }

  /// 踢出成员
  void _handleKickMember(
    BuildContext context,
    WidgetRef ref,
    String roomId,
    int targetUserId,
    String targetUserName,
  ) {
    // 弹出确认对话框
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认踢出'),
        content: Text('确定要将「$targetUserName」踢出该群聊吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              // 显示加载提示
              final cancelLoading = BotToast.showLoading();

              try {
                final success = await ref
                    .read(roomMemberServiceProvider.notifier)
                    .kickMember(roomId, targetUserId);

                cancelLoading();

                if (success) {
                  BotToast.showText(text: '踢出成功');
                } else {
                  BotToast.showText(text: '踢出失败，请重试');
                }
              } catch (e) {
                cancelLoading();
                BotToast.showText(text: '操作失败：$e');
              }
            },
            child: Text(
              '确定',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  /// 房间禁言/解除禁言
  void _handleMuteRoom(
    BuildContext context,
    WidgetRef ref,
    String roomId,
    bool isMute,
  ) {
    // 弹出确认对话框
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isMute ? '全员禁言' : '解除禁言'),
        content: Text(
          isMute ? '确定要开启全员禁言吗？开启后所有成员都不能发言。' : '确定要解除全员禁言吗？解除后所有成员都可以发言。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              // 显示加载提示
              final cancelLoading = BotToast.showLoading();

              try {
                final success = await ref
                    .read(roomListServiceProvider.notifier)
                    .muteRoom(roomId, isMute);

                cancelLoading();

                if (success) {
                  BotToast.showText(text: isMute ? '已开启全员禁言' : '已解除全员禁言');
                } else {
                  BotToast.showText(text: '操作失败，请重试');
                }
              } catch (e) {
                cancelLoading();
                BotToast.showText(text: '操作失败：$e');
              }
            },
            child: Text(
              '确定',
              style: TextStyle(
                color: isMute
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
