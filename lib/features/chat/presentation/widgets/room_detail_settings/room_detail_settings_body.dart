import 'package:anoxia/common/widgets/adaptive_page_presenter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/widgets/dialogs/danger_confirm_dialog.dart';
import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/common/widgets/vibrating_badge.dart';
import 'package:anoxia/features/chat/presentation/widgets/room_detail_settings/member_list_section.dart';
import 'package:anoxia/features/chat/presentation/widgets/room_detail_settings/room_card.dart';
import 'package:anoxia/features/chat/presentation/widgets/search_context_page.dart';
import 'package:anoxia/features/chat/presentation/widgets/chat_room_picker_dialog.dart';
import 'package:anoxia/features/chat/presentation/pages/add_member_page.dart';
import 'package:anoxia/features/chat/presentation/pages/member_basic_info_page.dart';
import 'package:anoxia/features/chat/presentation/pages/group_member_list_page.dart';
import 'package:anoxia/features/chat/presentation/pages/group_join_requests_page.dart';
import 'package:anoxia/features/chat/presentation/pages/group_edit_name_page.dart';
import 'package:anoxia/features/chat/presentation/pages/group_edit_announcement_page.dart';
import 'package:anoxia/features/chat/presentation/pages/group_announcement_detail_page.dart';
import 'package:anoxia/features/chat/presentation/pages/group_qr_page.dart';
import 'package:anoxia/features/contact/presentation/pages/contact_detail_page.dart';
import 'package:anoxia/framework/domain/chat_room_member_vo.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/framework/provider/chat/room/do_not_disturb_rooms_provider.dart';
import 'package:anoxia/framework/provider/chat/room/group_join_service.dart';
import 'package:anoxia/framework/provider/chat/room/pinned_rooms_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/provider/contact/contact_selection_controller.dart';
import 'package:anoxia/features/chat/presentation/widgets/room_detail_settings/official_room_help_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

/// 房间详情设置的核心内容（成员网格 + 资料 + 通知开关 + 危险操作）
///
/// 不包含 Scaffold/AppBar，供移动端整页和桌面端右侧面板共同复用：
/// - 移动端：[ChatRoomDetailSettingsPage] 包一层 Scaffold + AppBar
/// - 桌面端：[ChatRoomDetailPanel] 包一层轻量 Header，嵌入右侧固定面板
class RoomDetailSettingsBody extends ConsumerWidget {
  final String roomId;
  final EdgeInsetsGeometry padding;

  const RoomDetailSettingsBody({
    super.key,
    required this.roomId,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoom = ref.watch(currentRoomProvider(roomId));
    if (currentRoom == null) {
      return const _SettingsBodySkeleton();
    }

    // 官方虚拟房间：展示选项式帮助，不渲染成员 / 资料 / 危险操作
    if (currentRoom.isOfficial) {
      return const OfficialRoomHelpPanel();
    }

    final isGroup = currentRoom.roomType == 1;
    final currentUser = ref.watch(authControllerProvider).value;
    final isAdmin = ref.watch(
      isRoomAdminProvider((roomId, currentUser?.userId ?? 0)),
    );

    return ListView(
      padding: padding,
      children: [
        // 区块 0：群成员行式列表
        RoomCard(
          child: MemberListSection(
            roomId: roomId,
            isGroup: isGroup,
            onMemberTap: (member) =>
                _openContactDetailByMember(context, ref, member),
            onAddMemberTap: !isGroup
                ? null
                : () {
                    presentAdaptivePage(
                      context,
                      builder: (_) => AddMemberPage(
                        roomId: roomId,
                        roomName: currentRoom.roomName ?? '',
                      ),
                    );
                  },
          ),
        ),

        // 区块 1：会话/群聊基础资料管理
        RoomCard(
          children: [
            _buildMaterialListTile(
              context,
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedUserMultiple02,
                size: 22,
              ),
              title: Text(
                isGroup
                    ? 'chat_view_all_members'.tr()
                    : 'chat_contact_info'.tr(),
              ),
              subtitle: isGroup
                  ? Consumer(
                      builder: (context, ref, child) {
                        final members = ref.watch(roomMembersProvider(roomId));
                        return Text(
                          'chat_total_members_count'.tr(
                            args: [members.length.toString()],
                          ),
                        );
                      },
                    )
                  : null,
              trailing: const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 14,
              ),
              onTap: () async {
                if (isGroup) {
                  await presentAdaptivePage(
                    context,
                    builder: (_) => GroupMemberListPage(
                      roomId: roomId,
                      roomName: currentRoom.roomName ?? '',
                    ),
                  );
                  return;
                }

                final peerId = currentRoom.peerId;
                if (peerId == null) {
                  Toast.showToast(
                    'chat_operation_retry_failed'.tr(),
                    type: ToastType.error,
                  );
                  return;
                }

                var contactMap = ref.read(contactListServiceProvider).value;

                if (contactMap == null || !contactMap.containsKey(peerId)) {
                  await ref
                      .read(contactListServiceProvider.notifier)
                      .refresh(quiet: true);
                  contactMap = ref.read(contactListServiceProvider).value;
                }

                final contact = contactMap?[peerId];
                if (contact == null) {
                  Toast.showToast(
                    'chat_operation_retry_failed'.tr(),
                    type: ToastType.error,
                  );
                  return;
                }

                ref
                    .read(contactSelectionProvider.notifier)
                    .selectContact(contact);

                if (context.mounted) {
                  await presentAdaptivePage(
                    context,
                    builder: (_) => const ContactDetail(),
                  );
                }
              },
            ),
            if (isGroup) ...[
              _buildMaterialListTile(
                context,
                leading: const HugeIcon(
                  icon: HugeIcons.strokeRoundedComment01,
                  size: 22,
                ),
                title: Text('chat_group_name'.tr()),
                subtitle: Text(
                  currentRoom.roomName ?? currentRoom.roomDescription ?? '',
                ),
                trailing: const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 14,
                ),
                onTap: () {
                  presentAdaptivePage(
                    context,
                    builder: (_) => GroupEditNamePage(
                      roomId: roomId,
                      initialName: currentRoom.roomName ?? '',
                    ),
                  );
                },
              ),
              _buildMaterialListTile(
                context,
                leading: const HugeIcon(
                  icon: HugeIcons.strokeRoundedMegaphone01,
                  size: 22,
                ),
                title: Text('chat_group_announcement'.tr()),
                subtitle: Text(currentRoom.roomDescription ?? ''),
                trailing: HugeIcon(
                  icon: isAdmin
                      ? HugeIcons.strokeRoundedEdit02
                      : HugeIcons.strokeRoundedArrowRight01,
                  size: isAdmin ? 18 : 14,
                ),
                onTap: () {
                  presentAdaptivePage(
                    context,
                    builder: (_) => isAdmin
                        ? GroupEditAnnouncementPage(
                            roomId: roomId,
                            initialAnnouncement:
                                currentRoom.roomDescription ?? '',
                          )
                        : GroupAnnouncementDetailPage(roomId: roomId),
                  );
                },
              ),
              _buildMaterialListTile(
                context,
                leading: const HugeIcon(
                  icon: HugeIcons.strokeRoundedQrCode01,
                  size: 22,
                ),
                title: Text('chat_group_qr_code'.tr()),
                trailing: const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 14,
                ),
                onTap: () {
                  presentAdaptivePage(
                    context,
                    builder: (_) => GroupQrPage(roomId: roomId),
                  );
                },
              ),
              _buildMaterialListTile(
                context,
                leading: const HugeIcon(
                  icon: HugeIcons.strokeRoundedShare08,
                  size: 22,
                ),
                title: Text('chat_share_group'.tr()),
                trailing: const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 14,
                ),
                onTap: () async {
                  if (currentRoom.roomStatus == 2 ||
                      currentRoom.roomStatus == 3) {
                    Toast.showToast(
                      'group_card_unavailable'.tr(),
                      type: ToastType.warning,
                    );
                    return;
                  }
                  final destination = await showChatRoomPicker(context);
                  if (destination?.roomId == null) return;
                  final members = ref.read(roomMembersProvider(roomId));
                  final card = CardPayload(
                    cardType: 'group',
                    entityId: roomId,
                    title: currentRoom.roomName,
                    summary: currentRoom.roomDescription,
                    thumbnailUrl: currentRoom.roomAvatar,
                    properties: {
                      'memberCount': members.length.toString(),
                      'roomStatus': (currentRoom.roomStatus ?? -1).toString(),
                      'joinPolicy': (currentRoom.joinPolicy ?? 1).toString(),
                    },
                  );
                  final sent = ref
                      .read(
                        chatInputControllerProvider(
                          destination!.roomId!,
                        ).notifier,
                      )
                      .sendCardMessage(card);
                  Toast.showToast(
                    sent
                        ? 'group_card_shared'.tr()
                        : 'contact_recommend_send_failed'.tr(),
                    type: sent ? ToastType.success : ToastType.error,
                  );
                },
              ),
              // 需审批群才展示入群申请入口，自由加入群（joinPolicy==0）无需审批
              if (isAdmin && currentRoom.joinPolicy != 0)
                _buildMaterialListTile(
                  context,
                  leading: const HugeIcon(
                    icon: HugeIcons.strokeRoundedUserCheck01,
                    size: 22,
                  ),
                  title: Text('group_join_requests_title'.tr()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _JoinRequestsBadge(roomId: roomId),
                      const SizedBox(width: 6),
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        size: 14,
                      ),
                    ],
                  ),
                  onTap: () => presentAdaptivePage(
                    context,
                    builder: (_) => GroupJoinRequestsPage(roomId: roomId),
                  ),
                ),
            ],
          ],
        ),

        // 区块 2：核心功能（搜索聊天记录）
        RoomCard(
          child: _buildMaterialListTile(
            context,
            leading: const HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              size: 22,
            ),
            title: Text('search_context_title'.tr()),
            trailing: const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 14,
            ),
            onTap: () {
              presentAdaptivePage(
                context,
                builder: (_) => SearchContextPage(
                  roomId: roomId,
                  roomName: currentRoom.roomName ?? '',
                ),
              );
            },
          ),
        ),

        // 区块 3：通知与会话常规开关设置
        RoomCard(
          children: [
            _RoomSwitchTile(
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedPin,
                size: 22,
              ),
              title: Text('chat_pin'.tr()),
              value: ref.watch(pinnedRoomsProvider).contains(roomId),
              onChanged: (value) async {
                await ref.read(pinnedRoomsProvider.notifier).toggle(roomId);
              },
            ),
            _RoomSwitchTile(
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedNotificationOff02,
                size: 22,
              ),
              title: Text('chat_do_not_disturb'.tr()),
              subtitle: Text('chat_do_not_disturb_hint'.tr()),
              value: ref.watch(doNotDisturbRoomsProvider).contains(roomId),
              onChanged: (value) async {
                await ref
                    .read(doNotDisturbRoomsProvider.notifier)
                    .setEnabled(roomId, value);
              },
            ),
            if (isGroup && isAdmin)
              _RoomSwitchTile(
                leading: const HugeIcon(
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
                    Toast.showToast(
                      value
                          ? 'chat_mute_success'.tr()
                          : 'chat_unmute_success'.tr(),
                      type: ToastType.success,
                    );
                  } else {
                    Toast.showToast(
                      'chat_operation_retry_failed'.tr(),
                      type: ToastType.error,
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
    );
  }

  Widget _buildMaterialListTile(
    BuildContext context, {
    Widget? leading,
    Widget? title,
    Widget? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Future<void> _openContactDetailByMember(
    BuildContext context,
    WidgetRef ref,
    ChatRoomMemberVO member,
  ) async {
    var contactMap = ref.read(contactListServiceProvider).value;

    if (contactMap == null || !contactMap.containsKey(member.userId)) {
      await ref.read(contactListServiceProvider.notifier).refresh(quiet: true);
      contactMap = ref.read(contactListServiceProvider).value;
    }

    final contact = contactMap?[member.userId];

    // 成员还不是联系人时，展示群成员基础资料
    if (contact == null) {
      if (context.mounted) {
        await presentAdaptivePage(
          context,
          builder: (_) => MemberBasicInfoPage(member: member),
        );
      }
      return;
    }

    ref.read(contactSelectionProvider.notifier).selectContact(contact);

    if (context.mounted) {
      await presentAdaptivePage(context, builder: (_) => const ContactDetail());
    }
  }

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
      onTap = () => _runDangerAction(
        context,
        ref,
        icon: HugeIcons.strokeRoundedCancel01,
        title: 'chat_dissolve_group'.tr(),
        content: 'chat_dissolve_group_confirm_hint'.tr(),
        confirmLabel: 'chat_dissolve_group'.tr(),
        action: () =>
            ref.read(roomListServiceProvider.notifier).dissolveGroup(roomId),
      );
    } else if (isGroup) {
      actionLabel = 'chat_exit_group'.tr();
      onTap = () => _runDangerAction(
        context,
        ref,
        icon: HugeIcons.strokeRoundedLogout01,
        title: 'chat_exit_group'.tr(),
        content: 'chat_exit_group_confirm_hint'.tr(),
        confirmLabel: 'chat_exit_group'.tr(),
        action: () =>
            ref.read(roomListServiceProvider.notifier).leaveRoom(roomId),
      );
    } else {
      actionLabel = 'chat_delete_conversation'.tr();
      onTap = () => _runDangerAction(
        context,
        ref,
        icon: HugeIcons.strokeRoundedDelete02,
        title: 'chat_delete_conversation'.tr(),
        content: 'chat_delete_conversation_confirm_hint'.tr(),
        confirmLabel: 'chat_delete_conversation'.tr(),
        action: () =>
            ref.read(roomListServiceProvider.notifier).leaveRoom(roomId),
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

  /// 危险操作流程：弹出确认弹窗 → 执行操作 → 清空活跃房间并返回会话列表。
  ///
  /// 移动端设置页由 [Navigator] 压栈进入，操作后需连同聊天详情页一起弹回；
  /// 桌面端为内嵌右侧面板（无压栈），`popUntil` 是空操作，仅清空活跃房间即可。
  Future<void> _runDangerAction(
    BuildContext context,
    WidgetRef ref, {
    required List<List<dynamic>> icon,
    required String title,
    required String content,
    required String confirmLabel,
    required Future<void> Function() action,
  }) async {
    final confirmed = await showDangerConfirmDialog(
      context,
      icon: icon,
      title: title,
      content: content,
      confirmLabel: confirmLabel,
    );
    if (!confirmed || !context.mounted) return;

    await action();
    if (!context.mounted) return;

    // 清空活跃房间，回到会话列表（不再导航到不存在的 /chat 路由）
    ref.read(activeRoomIdProvider.notifier).setActive(null);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

/// 紧凑型开关行：缩小开关控件与行高，适配会话详情侧栏。
class _RoomSwitchTile extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RoomSwitchTile({
    required this.leading,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      minVerticalPadding: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: Transform.scale(
        scale: 0.78,
        child: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      onTap: () => onChanged(!value),
    );
  }
}

/// 「入群申请」入口的待处理数量徽标
///
/// 进入设置页时静默刷新一次，数量变化时展示红点徽章。
class _JoinRequestsBadge extends ConsumerStatefulWidget {
  final String roomId;

  const _JoinRequestsBadge({required this.roomId});

  @override
  ConsumerState<_JoinRequestsBadge> createState() => _JoinRequestsBadgeState();
}

class _JoinRequestsBadgeState extends ConsumerState<_JoinRequestsBadge> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(groupJoinRequestsServiceProvider(widget.roomId).notifier)
          .refresh(widget.roomId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = ref.watch(
      pendingGroupJoinRequestCountProvider(widget.roomId),
    );
    return VibratingBadge(count: pendingCount.value ?? 0, size: 16);
  }
}

/// 房间设置面板骨架屏
///
/// 模拟真实布局：成员卡片 + 若干设置行卡片（图标 + 标题 + 尾部箭头）。
class _SettingsBodySkeleton extends StatelessWidget {
  const _SettingsBodySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // 区块 0：成员行
        const _SkeletonCard(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                SkeletonBox(width: 40, height: 40, circle: true),
                SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 14, radius: 5)),
                SkeletonBox(width: 18, height: 18, radius: 5),
              ],
            ),
          ),
        ),
        // 区块 1：资料/通知等设置行
        _SkeletonCard(
          child: Column(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 56, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      const SkeletonBox(width: 22, height: 22, radius: 6),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SkeletonLine(width: 96 - (i % 3) * 16, height: 13),
                      ),
                      const SkeletonBox(width: 14, height: 14, radius: 4),
                    ],
                  ),),
              ],
            ],
          ),
        ),
        // 区块 2：危险操作
        const _SkeletonCard(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                SkeletonBox(width: 22, height: 22, radius: 6),
                SizedBox(width: 14),
                Expanded(child: SkeletonLine(width: 72, height: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 骨架卡片：与 [RoomCard] 同款圆角容器
class _SkeletonCard extends StatelessWidget {
  final Widget child;

  const _SkeletonCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
