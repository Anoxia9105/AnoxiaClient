import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/framework/domain/ChatRoomVO.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

/// 聊天房间详情设置页
class ChatRoomDetailSettingsPage extends ConsumerWidget {
  final ChatRoomVO room;
  const ChatRoomDetailSettingsPage({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final currentRoom = ref.watch(currentRoomProvider(room.roomId ?? '')) ?? room;

    // 监听房间成员
    final members = ref.watch(roomMembersProvider(currentRoom.roomId ?? ''));
    final isGroup = currentRoom.roomType == 1;

    /// 当前用户信息
    final currentUser = ref.watch(authControllerProvider).value;

    // 当前用户是否是管理员
    final isAdmin = ref.watch(
      isRoomAdminProvider((currentRoom.roomId ?? '', currentUser?.userId ?? 0)),
    );

    // 计算顶部网格展示逻辑：最多展示 19 人，留 1 个位置给“邀请加号”按钮
    final maxGridItems = isGroup ? 20 : 1;
    final displayCount = members.length > (maxGridItems - 1) && isGroup
        ? (maxGridItems - 1)
        : members.length;

    return Scaffold(
      // 使用更柔和的背景色，衬托卡片区块
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: Text('chat_conversation_detail'.tr()),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // --- 🌟 区块 0：顶部成员网格卡片 ---
          _buildSection(context, [
            Padding(
              padding: const EdgeInsets.all(8),
              child: GridView.builder(
                // 修复关键 1：禁止 GridView 独立滚动，让其跟随外层 ListView
                physics: const NeverScrollableScrollPhysics(),
                // 修复关键 2：包裹内容，自动计算网格高度
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5, // 移动端 5 列视觉更紧凑美观
                  childAspectRatio: 0.85, // 调大纵横比，为底部名字留出空间，防止文本溢出
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: isGroup
                    ? (displayCount + 1)
                    : displayCount, // +1 是留给加号的
                itemBuilder: (context, index) {
                  // 渲染“添加成员”加号按钮
                  if (isGroup && index == displayCount) {
                    return _buildActionButton(
                      context,
                      icon: HugeIcons.strokeRoundedAdd01,
                      label: 'member_add_title'.tr(),
                      onTap: () {
                        /// TODO: 打开选择联系人邀请入群页面
                      },
                    );
                  }

                  final member = members[index];
                  return GestureDetector(
                    onTap: () {
                      /// TODO: 跳转到成员个人主页
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AvatarWidget(
                          url: member.avatar,
                          name: member.nickName,
                          size: 44, // 稍微加大尺寸
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Center(
                            child: Text(
                              member.nickName ?? '未知用户',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ]),

          // --- 区块 1：群成员管理入口 ---
          _buildSection(context, [
            ListTile(
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedUserMultiple02,
                size: 22,
              ),
              title: Text(
                isGroup ? 'chat_group_members'.tr() : 'chat_view_profile'.tr(),
              ),
              subtitle: isGroup
                  ? Text(
                      'chat_total_members_count'.tr(
                        args: [members.length.toString()],
                      ),
                    )
                  : null,
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                /// TODO: 跳转到查看完整的群成员列表页面
              },
            ),
          ]),

          // --- 区块 2：核心功能（搜索与查找）---
          _buildSection(context, [
            ListTile(
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                size: 22,
              ),
              title: Text('search_context_title'.tr()),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.pop();
                }
                Future.microtask(() {
                  ref.read(roomListServiceProvider.notifier).toggleSearch();
                });
              },
            ),
          ]),

          // --- 区块 3：通知与会话设置 ---
          _buildSection(context, [
            SwitchListTile.adaptive(
              secondary: const HugeIcon(
                icon: HugeIcons.strokeRoundedNotificationOff01,
                size: 22,
              ),
              title: Text('chat_mute_notifications'.tr()),
              value: false, // TODO: 绑定状态
              onChanged: (value) {},
            ),

            SwitchListTile.adaptive(
              secondary: const HugeIcon(
                icon: HugeIcons.strokeRoundedPin,
                size: 22,
              ),
              title: Text('chat_pin'.tr()),
              value: false, // TODO: 绑定状态
              onChanged: (value) {},
            ),
            if (isAdmin)
              /// 全员禁言
              SwitchListTile.adaptive(
                secondary: const HugeIcon(
                  icon: HugeIcons.strokeRoundedVolumeHigh,
                  size: 22,
                ),
                title: Text('chat_mute_all'.tr()),
                value: currentRoom.roomStatus == 1,
                onChanged: (value) async {
                  if (currentRoom.roomId == null) return;

                  final targetMuteState = value;

                  final success = await ref
                      .read(roomListServiceProvider.notifier)
                      .muteRoom(currentRoom.roomId!, targetMuteState);
                  if (success) {
                    BotToast.showText(
                      text: targetMuteState
                          ? 'chat_mute_success'.tr()
                          : 'chat_unmute_success'.tr(),
                    );
                  } else {
                    BotToast.showText(text: 'chat_operation_retry_failed'.tr());
                  }
                },
              ),
          ]),

          // --- 区块 4：危险操作（退出/解散）---
          if (isGroup)
            _buildSection(context, [
              ListTile(
                title: Center(
                  child: Text(
                    'chat_exit_group'.tr(),
                    style: TextStyle(
                      color: colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () {
                  /// TODO: 弹出退出群聊确认弹窗
                },
              ),
            ]),
        ],
      ),
    );
  }

  /// 封装卡片容器（自动适配暗黑模式颜色）
  Widget _buildSection(BuildContext context, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        // 修复关键 3：使用 surface 替代纯白，完美适配 Dark Mode
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  /// 快捷构建网格内类似“+”号的虚线/圆圈功能按钮
  Widget _buildActionButton(
    BuildContext context, {
    required dynamic icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: HugeIcon(
              icon: icon,
              color: colorScheme.onSurfaceVariant,
              size: 18,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
