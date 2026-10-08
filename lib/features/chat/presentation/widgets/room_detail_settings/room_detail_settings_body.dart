import 'package:anoxia/common/widgets/adaptive_page_presenter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/widgets/dialogs/danger_confirm_dialog.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/chat/presentation/widgets/appbar/chat_bar_handlers.dart';
import 'package:anoxia/features/chat/presentation/widgets/room_detail_settings/member_list_section.dart';
import 'package:anoxia/features/chat/presentation/widgets/room_detail_settings/room_card.dart';
import 'package:anoxia/features/chat/presentation/widgets/room_detail_settings/room_detail_hero.dart';
import 'package:anoxia/features/chat/presentation/widgets/room_detail_settings/room_detail_settings_widgets.dart';
import 'package:anoxia/features/chat/presentation/widgets/room_detail_settings/room_setting_tile.dart';
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
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/framework/provider/chat/room/do_not_disturb_rooms_provider.dart';
import 'package:anoxia/framework/provider/chat/room/pinned_rooms_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/provider/contact/contact_selection_controller.dart';
import 'package:anoxia/features/chat/presentation/widgets/room_detail_settings/official_room_help_panel.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

/// 房间详情设置的核心内容（档案头 + 成员网格 + 快捷工具 + 资料 + 开关 + 危险操作）
///
/// 不包含 Scaffold/AppBar，供移动端整页和桌面端右侧面板共同复用：
/// - 移动端：[ChatRoomDetailSettingsPage] 包一层 Scaffold + AppBar
/// - 桌面端：[ChatRoomDetailPanel] 包一层轻量 Header，嵌入右侧固定面板
///
/// 只做 UI 重排：所有入口均指向已存在页面/流程，不新增功能。
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
      return const SettingsBodySkeleton();
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
    final members = ref.watch(roomMembersProvider(roomId));
    final onlineCount = members.where((m) => m.onlineStatus == true).length;

    return ListView(
      padding: padding,
      children: [
        // 档案头：头像 + 名称徽章 + 成员/在线（群）或在线状态（单聊）
        RoomDetailHero(
          avatarUrl: currentRoom.roomAvatar,
          displayName: _displayName(currentRoom),
          isGroup: isGroup,
          memberTotal: members.length,
          onlineCount: onlineCount,
          isAdmin: isAdmin,
          peerOnline: _peerOnline(currentRoom, members),
        ),

        // 区块 0：成员头像网格 + 查看全部入口
        RoomSectionCaption('chat_detail_members'.tr()),
        RoomCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MemberListSection(
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
              if (isGroup)
                _ViewAllFooter(
                  onTap: () => presentAdaptivePage(
                    context,
                    builder: (_) => GroupMemberListPage(
                      roomId: roomId,
                      roomName: currentRoom.roomName ?? '',
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 快捷工具：已存在二级页的前置入口
        RoomSectionCaption('chat_detail_quick_tools'.tr()),
        if (isGroup)
          _QuickTools(
            tools: [
              _QuickToolData(
                icon: HugeIcons.strokeRoundedSearch01,
                tint: SettingIconTint.blue,
                label: 'chat_detail_search'.tr(),
                onTap: () => _openSearch(context, currentRoom),
              ),
              _QuickToolData(
                icon: HugeIcons.strokeRoundedMegaphone01,
                tint: SettingIconTint.amber,
                label: 'chat_group_announcement'.tr(),
                onTap: () => _openAnnouncement(context, currentRoom, isAdmin),
              ),
              _QuickToolData(
                icon: HugeIcons.strokeRoundedQrCode01,
                tint: SettingIconTint.green,
                label: 'chat_group_qr_code'.tr(),
                onTap: () => presentAdaptivePage(
                  context,
                  builder: (_) => GroupQrPage(roomId: roomId),
                ),
              ),
              _QuickToolData(
                icon: HugeIcons.strokeRoundedShare08,
                tint: SettingIconTint.violet,
                label: 'chat_share_group'.tr(),
                onTap: () => _shareGroup(context, ref, currentRoom),
              ),
            ],
          )
        else
          _QuickTools(
            tools: [
              _QuickToolData(
                icon: HugeIcons.strokeRoundedSearch01,
                tint: SettingIconTint.blue,
                label: 'chat_detail_search'.tr(),
                onTap: () => _openSearch(context, currentRoom),
              ),
              _QuickToolData(
                icon: HugeIcons.strokeRoundedUserMultiple02,
                tint: SettingIconTint.teal,
                label: 'chat_contact_info'.tr(),
                onTap: () => _openPeerContact(context, ref, currentRoom),
              ),
              _QuickToolData(
                icon: HugeIcons.strokeRoundedCall02,
                tint: SettingIconTint.green,
                label: 'call_audio_call'.tr(),
                onTap: () => ChatBarHandlers.onCallPressed(
                  context,
                  ref,
                  currentRoom,
                  initialMedia: CallInitialMedia.audio,
                ),
              ),
              _QuickToolData(
                icon: HugeIcons.strokeRoundedVideo01,
                tint: SettingIconTint.violet,
                label: 'call_video_call'.tr(),
                onTap: () => ChatBarHandlers.onCallPressed(
                  context,
                  ref,
                  currentRoom,
                  initialMedia: CallInitialMedia.video,
                ),
              ),
            ],
          ),

        if (isGroup) ...[
          // 区块 1：群聊基础资料管理
          RoomSectionCaption('chat_detail_group_management'.tr()),
          RoomCard(
            children: _withDividers(context, [
              RoomSettingTile(
                icon: HugeIcons.strokeRoundedComment01,
                tint: SettingIconTint.blue,
                title: Text('chat_group_name'.tr()),
                subtitle: Text(
                  currentRoom.roomName ?? currentRoom.roomDescription ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
              RoomSettingTile(
                icon: HugeIcons.strokeRoundedMegaphone01,
                tint: SettingIconTint.amber,
                title: Text('chat_group_announcement'.tr()),
                subtitle: Text(
                  currentRoom.roomDescription ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: HugeIcon(
                  icon: isAdmin
                      ? HugeIcons.strokeRoundedEdit02
                      : HugeIcons.strokeRoundedArrowRight01,
                  size: isAdmin ? 18 : 15,
                  color: Theme.of(context).colorScheme.outline,
                ),
                showChevron: false,
                onTap: () => _openAnnouncement(context, currentRoom, isAdmin),
              ),
              RoomSettingTile(
                icon: HugeIcons.strokeRoundedQrCode01,
                tint: SettingIconTint.green,
                title: Text('chat_group_qr_code'.tr()),
                subtitle: Text('chat_group_qr_hint'.tr()),
                onTap: () {
                  presentAdaptivePage(
                    context,
                    builder: (_) => GroupQrPage(roomId: roomId),
                  );
                },
              ),
              RoomSettingTile(
                icon: HugeIcons.strokeRoundedShare08,
                tint: SettingIconTint.violet,
                title: Text('chat_share_group'.tr()),
                subtitle: Text(
                  'chat_share_group_hint'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _shareGroup(context, ref, currentRoom),
              ),
              // 需审批群才展示入群申请入口，自由加入群（joinPolicy==0）无需审批
              if (isAdmin && currentRoom.joinPolicy != 0)
                RoomSettingTile(
                  icon: HugeIcons.strokeRoundedUserCheck01,
                  tint: SettingIconTint.violet,
                  title: Text('group_join_requests_title'.tr()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      JoinRequestsBadge(roomId: roomId),
                      const SizedBox(width: 6),
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        size: 15,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ],
                  ),
                  showChevron: false,
                  onTap: () => presentAdaptivePage(
                    context,
                    builder: (_) => GroupJoinRequestsPage(roomId: roomId),
                  ),
                ),
            ]),
          ),

          // 区块 3：通知与会话常规开关设置
          RoomSectionCaption('chat_detail_notify'.tr()),
          RoomCard(
            children: _withDividers(context, [
              _pinTile(context, ref),
              _dndTile(context, ref),
              if (isAdmin) _muteAllTile(context, ref, currentRoom),
            ]),
          ),
        ] else ...[
          // 单聊：联系人资料 + 常规开关
          RoomSectionCaption('chat_detail_settings'.tr()),
          RoomCard(
            children: _withDividers(context, [
              RoomSettingTile(
                icon: HugeIcons.strokeRoundedUserMultiple02,
                tint: SettingIconTint.blue,
                title: Text('chat_contact_info'.tr()),
                onTap: () => _openPeerContact(context, ref, currentRoom),
              ),
              _pinTile(context, ref),
              _dndTile(context, ref),
            ]),
          ),
        ],

        // 区块 4：底部危险动作
        RoomSectionCaption('chat_detail_danger'.tr()),
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

  // ---------- 展示数据 ----------

  String _displayName(ChatRoomVO room) {
    final name = room.roomName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    return (room.roomDescription?.trim().isNotEmpty == true)
        ? room.roomDescription!.trim()
        : '';
  }

  bool _peerOnline(ChatRoomVO room, List<ChatRoomMemberVO> members) {
    final peerId = room.peerId;
    if (peerId == null || members.isEmpty) return false;
    for (final m in members) {
      if (m.userId == peerId) return m.onlineStatus == true;
    }
    return members.first.onlineStatus == true;
  }

  // ---------- 开关行 ----------

  Widget _pinTile(BuildContext context, WidgetRef ref) {
    return RoomSwitchTile(
      leading: const _TileIcon(
        icon: HugeIcons.strokeRoundedPin,
        tint: SettingIconTint.grey,
      ),
      title: Text('chat_pin'.tr()),
      subtitle: Text('chat_pin_hint'.tr()),
      value: ref.watch(pinnedRoomsProvider).contains(roomId),
      onChanged: (value) async {
        await ref.read(pinnedRoomsProvider.notifier).toggle(roomId);
      },
    );
  }

  Widget _dndTile(BuildContext context, WidgetRef ref) {
    return RoomSwitchTile(
      leading: const _TileIcon(
        icon: HugeIcons.strokeRoundedNotificationOff02,
        tint: SettingIconTint.rose,
      ),
      title: Text('chat_do_not_disturb'.tr()),
      subtitle: Text('chat_do_not_disturb_hint'.tr()),
      value: ref.watch(doNotDisturbRoomsProvider).contains(roomId),
      onChanged: (value) async {
        await ref.read(doNotDisturbRoomsProvider.notifier).setEnabled(
              roomId,
              value,
            );
      },
    );
  }

  Widget _muteAllTile(
    BuildContext context,
    WidgetRef ref,
    ChatRoomVO currentRoom,
  ) {
    return RoomSwitchTile(
      leading: const _TileIcon(
        icon: HugeIcons.strokeRoundedVolumeHigh,
        tint: SettingIconTint.teal,
      ),
      title: Text('chat_mute_all'.tr()),
      value: currentRoom.roomStatus == 1,
      onChanged: (value) async {
        final success = await ref
            .read(roomListServiceProvider.notifier)
            .muteRoom(roomId, value);
        if (success) {
          Toast.showToast(
            value ? 'chat_mute_success'.tr() : 'chat_unmute_success'.tr(),
            type: ToastType.success,
          );
        } else {
          Toast.showToast(
            'chat_operation_retry_failed'.tr(),
            type: ToastType.error,
          );
        }
      },
    );
  }

  // ---------- 二级页直达（行为与原来完全一致） ----------

  void _openSearch(BuildContext context, ChatRoomVO room) {
    presentAdaptivePage(
      context,
      builder: (_) => SearchContextPage(
        roomId: roomId,
        roomName: room.roomName ?? '',
      ),
    );
  }

  void _openAnnouncement(
    BuildContext context,
    ChatRoomVO room,
    bool isAdmin,
  ) {
    presentAdaptivePage(
      context,
      builder: (_) => isAdmin
          ? GroupEditAnnouncementPage(
              roomId: roomId,
              initialAnnouncement: room.roomDescription ?? '',
            )
          : GroupAnnouncementDetailPage(roomId: roomId),
    );
  }

  Future<void> _shareGroup(
    BuildContext context,
    WidgetRef ref,
    ChatRoomVO currentRoom,
  ) async {
    if (currentRoom.roomStatus == 2 || currentRoom.roomStatus == 3) {
      Toast.showToast('group_card_unavailable'.tr(), type: ToastType.warning);
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
          chatInputControllerProvider(destination!.roomId!).notifier,
        )
        .sendCardMessage(card);
    Toast.showToast(
      sent ? 'group_card_shared'.tr() : 'contact_recommend_send_failed'.tr(),
      type: sent ? ToastType.success : ToastType.error,
    );
  }

  /// 单聊对方联系人资料（行为与原来的「查看」行完全一致）
  Future<void> _openPeerContact(
    BuildContext context,
    WidgetRef ref,
    ChatRoomVO currentRoom,
  ) async {
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
      await ref.read(contactListServiceProvider.notifier).refresh(quiet: true);
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

    ref.read(contactSelectionProvider.notifier).selectContact(contact);
    if (context.mounted) {
      await presentAdaptivePage(
        context,
        builder: (_) => const ContactDetail(),
      );
    }
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
            action: () => ref
                .read(roomListServiceProvider.notifier)
                .dissolveGroup(roomId),
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

    // 危险区：左右留边距的居中长按钮，淡红底 + 红字
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(RadiusToken.lg);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Material(
        color: colorScheme.error.withValues(alpha: 0.1),
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Center(
              child: Text(
                actionLabel,
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
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

  /// 在卡片行之间插入 hairline 分隔线
  /// （indent 62 = 左右边距 14 + 图标块 36 + 间距 12，与标题左对齐）
  List<Widget> _withDividers(BuildContext context, List<Widget> tiles) {
    if (tiles.length < 2) return tiles;
    final dividerColor =
        Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5);
    final result = <Widget>[tiles.first];
    for (var i = 1; i < tiles.length; i++) {
      result.add(Divider(height: 1, indent: 62, endIndent: 14, color: dividerColor));
      result.add(tiles[i]);
    }
    return result;
  }
}

/// 开关行/设置行共用的彩色图标底块
class _TileIcon extends StatelessWidget {
  final List<List<dynamic>> icon;
  final SettingIconTint tint;

  const _TileIcon({required this.icon, required this.tint});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = tint.resolve(context);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
      ),
      alignment: Alignment.center,
      child: HugeIcon(icon: icon, size: 19, color: foreground),
    );
  }
}

/// 「查看全部成员」脚（群聊）
class _ViewAllFooter extends StatelessWidget {
  final VoidCallback onTap;

  const _ViewAllFooter({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(
          height: 1,
          indent: 14,
          endIndent: 14,
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'chat_view_all_members'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                ),
                const SizedBox(width: 4),
                HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 14,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickToolData {
  final List<List<dynamic>> icon;
  final SettingIconTint tint;
  final String label;
  final VoidCallback onTap;

  const _QuickToolData({
    required this.icon,
    required this.tint,
    required this.label,
    required this.onTap,
  });
}

/// 快捷工具：一排四个已存在页面的直达入口
///
/// 窄面板（桌面 320/280 右栏）自动切换为纯图标按钮 + Tooltip，
/// 避免文字挤压；移动端整页保留图标 + 文字。
class _QuickTools extends StatelessWidget {
  final List<_QuickToolData> tools;

  const _QuickTools({required this.tools});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 340;
          return Row(
            children: [
              for (var i = 0; i < tools.length; i++) ...[
                if (i > 0) const SizedBox(width: 9),
                Expanded(
                  child: _QuickToolButton(data: tools[i], compact: compact),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _QuickToolButton extends StatelessWidget {
  final _QuickToolData data;
  final bool compact;

  const _QuickToolButton({required this.data, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = data.tint.resolve(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.onTap,
        child: compact
            ? Tooltip(
                message: data.label,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(child: _toolIcon(context, background, foreground)),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _toolIcon(context, background, foreground),
                    const SizedBox(height: 7),
                    Text(
                      data.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _toolIcon(
    BuildContext context,
    Color background,
    Color foreground,
  ) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
      ),
      alignment: Alignment.center,
      child: HugeIcon(
        icon: data.icon,
        size: 19,
        color: foreground,
      ),
    );
  }
}
