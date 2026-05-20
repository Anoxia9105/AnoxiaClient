import 'package:anoxia/framework/domain/ChatRoomVO.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart'; // 如果用 context.pop()


/// 聊天房间详情设置页
///
/// 包含查看成员/用户信息、搜索聊天记录、消息免打扰、置顶聊天等功能入口
class ChatRoomDetailSettingsPage extends ConsumerWidget {
  final ChatRoomVO room;
  const ChatRoomDetailSettingsPage({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // 监听房间成员，用于展示成员管理入口或群成员微缩头像
    final members = ref.watch(roomMembersProvider(room.roomId ?? ''));
    final isGroup = room.roomType == 1;

    return Scaffold(
      backgroundColor: colorScheme.surface, // 浅灰色背景，突出区块感
      appBar: AppBar(
        title: Text("聊天信息"),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // --- 区块 1：群成员/用户信息 ---
          _buildSection([
            ListTile(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedUserMultiple02, size: 22),
              title: Text(isGroup ? 'chat_group_members'.tr() : 'chat_view_profile'.tr()),
              subtitle: isGroup ? Text('chat_total_members_count'.tr(args: [members.length.toString()])) : null,
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                /// TODO: 跳转到查看群成员列表页面
              },
            ),
          ]),

          // --- 区块 2：核心功能（搜索与查找）---
          _buildSection([
            ListTile(
              leading: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
              title: Text('chat_search_history'.tr()), // 查找聊天记录
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                // 1. 先关闭当前设置页，返回聊天房间
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.pop();
                }
                // 2. 延迟微秒触发聊天主页的搜索框展开，确保动画不冲突
                Future.microtask(() {
                  ref.read(roomListServiceProvider.notifier).toggleSearch();
                });
              },
            ),
          ]),

          // --- 区块 3：通知与会话设置 ---
          _buildSection([
            SwitchListTile.adaptive(
              secondary: const HugeIcon(icon: HugeIcons.strokeRoundedNotificationOff01, size: 22),
              title: Text('chat_mute_notifications'.tr()), // 消息免打扰
              value: false, // TODO: 绑定对应的 Provider 状态
              onChanged: (value) {
                // TODO: 切换免打扰状态
              },
            ),
            SwitchListTile.adaptive(
              secondary: const HugeIcon(icon: HugeIcons.strokeRoundedPin, size: 22),
              title: Text('chat_pin_room'.tr()), // 置顶聊天
              value: false, // TODO: 绑定对应的 Provider 状态
              onChanged: (value) {
                // TODO: 切换置顶状态
              },
            ),
          ]),

          // --- 区块 4：危险操作（退出/解散）---
          if (isGroup)
            _buildSection([
              ListTile(
                title: Center(
                  child: Text(
                    'chat_exit_group'.tr(), // 删除并退出
                    style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold),
                  ),
                ),
                onTap: () {
                  // TODO: 弹出退出群聊确认弹窗
                },
              ),
            ]),
        ],
      ),
    );
  }

  /// 封装 Material 3 样式的分组容器
  Widget _buildSection(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white, // 暗黑模式下建议改用 Theme.of(context).colorScheme.surface
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}