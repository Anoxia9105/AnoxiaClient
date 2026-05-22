import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/features/chat/presentation/widgets/room_detail_settings/member_grid_section.dart';
import 'package:anoxia/features/chat/presentation/widgets/room_detail_settings/room_card.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/room/pinned_rooms_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

/// 聊天房间详情设置页
///
/// 展示房间成员列表、搜索聊天记录、消息通知设置等功能。
/// 群聊还支持全员禁言、退出群聊等操作。
class ChatRoomDetailSettingsPage extends ConsumerWidget {
  /// 统一修改为只接收 roomId
  final String roomId;

  const ChatRoomDetailSettingsPage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    // 1. 实时监听最新的房间数据
    final currentRoom = ref.watch(currentRoomProvider(roomId));
    if (currentRoom == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isGroup = currentRoom.roomType == 1;
    final currentUser = ref.watch(authControllerProvider).value;
    final isAdmin = ref.watch(
      isRoomAdminProvider((roomId, currentUser?.userId ?? 0)),
    );

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: Text('chat_conversation_detail'.tr()),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // 区块 0：群成员头像网格
          RoomCard(
            child: MemberGridSection(roomId: roomId, isGroup: isGroup),
          ),

          // 区块 1：会话/群聊基础资料管理
          RoomCard(
            children: [
              ListTile(
                leading: const HugeIcon(
                  icon: HugeIcons.strokeRoundedUserMultiple02,
                  size: 22,
                ),
                title: Text(
                  isGroup
                      ? 'chat_group_members'.tr()
                      : 'chat_view_profile'.tr(),
                ),
                subtitle: isGroup
                    ? Consumer(
                        builder: (context, ref, child) {
                          final members = ref.watch(
                            roomMembersProvider(roomId),
                          );
                          return Text(
                            'chat_total_members_count'.tr(
                              args: [members.length.toString()],
                            ),
                          );
                        },
                      )
                    : null,
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  // TODO: 跳转至群成员详情列表
                },
              ),
              if (isGroup) ...[
                ListTile(
                  leading: const HugeIcon(
                    icon: HugeIcons.strokeRoundedComment01,
                    size: 22,
                  ), // 修复图标
                  title: Text('chat_group_name'.tr()),
                  subtitle: Text(
                    currentRoom.roomName ?? currentRoom.roomDescription ?? '',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {},
                ),
                ListTile(
                  leading: const HugeIcon(
                    icon: HugeIcons.strokeRoundedMegaphone01,
                    size: 22,
                  ),
                  title: Text('chat_group_announcement'.tr()),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {},
                ),
                ListTile(
                  leading: const HugeIcon(
                    icon: HugeIcons.strokeRoundedQrCode01,
                    size: 22,
                  ),
                  title: Text('chat_group_qr_code'.tr()),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    // TODO: 打开二维码展示页
                  },
                ),
              ],
            ],
          ),

          // 区块 2：核心功能（搜索聊天记录）
          RoomCard(
            child: ListTile(
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                size: 22,
              ),
              title: Text('search_context_title'.tr()),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                context.pop();
                Future.microtask(() {
                  ref.read(roomListServiceProvider.notifier).toggleSearch();
                });
              },
            ),
          ),

          // 区块 3：通知与会话常规开关设置
          RoomCard(
            children: [
              SwitchListTile.adaptive(
                secondary: const HugeIcon(
                  icon: HugeIcons.strokeRoundedPin,
                  size: 22,
                ),
                title: Text('chat_pin'.tr()),
                value: ref.watch(pinnedRoomsProvider).contains(roomId),
                onChanged: (value) async {
                  await ref.read(pinnedRoomsProvider.notifier).toggle(roomId);
                },
              ),
              if (isGroup && isAdmin)
                SwitchListTile.adaptive(
                  secondary: const HugeIcon(
                    icon: HugeIcons.strokeRoundedVolumeHigh,
                    size: 22,
                  ),
                  title: Text('chat_mute_all'.tr()),
                  value: currentRoom.roomStatus == 1,
                  onChanged: (value) async {
                    final success = await ref
                        .read(roomListServiceProvider.notifier)
                        .muteRoom(roomId, value);
                    if (success) {
                      BotToast.showText(
                        text: value
                            ? 'chat_mute_success'.tr()
                            : 'chat_unmute_success'.tr(),
                      );
                    } else {
                      BotToast.showText(
                        text: 'chat_operation_retry_failed'.tr(),
                      );
                    }
                  },
                ),
            ],
          ),

          // 区块 4：底部危险动作触发卡片
          _buildDangerActionCard(
            context,
            ref,
            isGroup,
            isAdmin,
            currentRoom.roomStatus ?? -1,
          ),
        ],
      ),
    );
  }

  /// 构建底部危险操作卡片
  Widget _buildDangerActionCard(
    BuildContext context,
    WidgetRef ref,
    bool isGroup,
    bool isAdmin,
    int roomStatus,
  ) {
    final String actionLabel;
    final VoidCallback onTap;

    if (isGroup && isAdmin && roomStatus == 0) {
      actionLabel = 'chat_dissolve_group'.tr();
      onTap = () => _showConfirmDialog(
        context,
        title: 'chat_dissolve_group'.tr(),
        content: 'chat_dissolve_group_confirm_hint'
            .tr(), // 确认要解散该群聊吗？解散后将清空所有数据。
        onConfirm: () async {
          await ref
              .read(roomListServiceProvider.notifier)
              .dissolveGroup(roomId);
          if (context.mounted) context.go('/chat'); // 回到聊天主页
        },
      );
    } else if (isGroup) {
      actionLabel = 'chat_exit_group'.tr(); // 退出群聊
      onTap = () => _showConfirmDialog(
        context,
        title: 'chat_exit_group'.tr(),
        content: 'chat_exit_group_confirm_hint'.tr(), // 确定要退出该群聊吗？
        onConfirm: () async {
          await ref.read(roomListServiceProvider.notifier).leaveRoom(roomId);
          if (context.mounted) context.go('/chat');
        },
      );
    } else {
      actionLabel = 'chat_delete_conversation'.tr();
      onTap = () => _showConfirmDialog(
        context,
        title: 'chat_delete_conversation'.tr(),
        content: 'chat_delete_conversation_confirm_hint'.tr(), // 确定删除该会话吗？
        onConfirm: () async {
          await ref.read(roomListServiceProvider.notifier).leaveRoom(roomId);
          if (context.mounted) context.go('/chat');
        },
      );
    }

    return RoomCard(
      child: ListTile(
        title: Center(
          child: Text(
            actionLabel,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  /// 通用二次确认适配弹窗
  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'cancel'.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: Text(
              'confirm'.tr(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
