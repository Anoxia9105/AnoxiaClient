import 'package:anoxia/common/widgets/BubbleDialog.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../common/utils/DateUtil.dart';
import '../../../common/widgets/AvatarWidget.dart';
import '../../../common/widgets/VibratingBadge.dart';
import '../../../framework/domain/ChatRoomVO.dart';
import '../../../framework/provider/chat/room/room_list_service.dart';

class ChatRoomList extends ConsumerStatefulWidget {
  const ChatRoomList({super.key});

  @override
  ConsumerState createState() => _ChatRoomListState();
}

class _ChatRoomListState extends ConsumerState<ChatRoomList> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final roomListAsync = ref.watch(roomListServiceProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Expanded(
              child: SizedBox(
                child: TextField(
                  onChanged: (val) =>
                      ref.read(roomSearchQueryProvider.notifier).update(val),
                  maxLength: 20,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    counterText: '',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    // 当有文字时显示清除按钮
                    suffixIcon: ref.watch(roomSearchQueryProvider).isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(roomSearchQueryProvider.notifier)
                                  .update("");
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: '搜索会话...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Builder(
              builder: (context) {
                return IconButton(
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedLayerAdd),
                  onPressed: () => _showAddRoomDetail(context),
                );
              },
            ),
          ],
        ),
      ),
      // 2. 使用 AsyncValue 的 when 模式处理不同状态
      body: roomListAsync.when(
        data: (rooms) => _buildRoomList(context, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('加载失败')),
      ),
    );
  }

  void _showAddRoomDetail(BuildContext context) {
    Function? close;
    close = Toast.showWidget(
      context,
      direction: PreferDirection.bottomLeft,
      child: Material(
        color: Colors.transparent,
        child: BubbleWidget(
          arrowDirection: AxisDirection.up,
          arrowOffset: 25,
          backgroundColor: Theme.of(context).colorScheme.surface,
          border: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
          contentBuilder: (context) => Container(
            constraints: BoxConstraints(maxWidth: 220, maxHeight: 600),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      _showCreateChatDialog(context);
                      close?.call();
                    },
                    label: Text("发起群聊"),
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedChatting01,
                      size: 18,
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      close?.call();
                    },
                    label: Text("添加朋友"),
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedUserAdd01,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _showCreateChatDialog(BuildContext context) {
    showDialog(
      context: context,
      // ✨ 关键 1: 禁止点击背景遮罩关闭
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias, // 确保子组件不会超出圆角边界
          child: SizedBox(
            width: 800,  // 宽度大幅提升
            height: 600, // 固定高度
            child: Stack(
              children: [
                // --- 对话框主体内容 ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "发起新聊天",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),

                      _buildDialogItem(
                        context,
                        icon: HugeIcons.strokeRoundedUser,
                        color: Colors.blue,
                        label: "新建私聊",
                        subtitle: "与单个联系人开始对话",
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: 处理私聊
                        },
                      ),

                      const SizedBox(height: 12),

                      _buildDialogItem(
                        context,
                        icon: HugeIcons.strokeRoundedUserGroup,
                        color: Colors.orange,
                        label: "创建群聊",
                        subtitle: "建立多人讨论小组",
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: 处理群聊
                        },
                      ),
                    ],
                  ),
                ),

                // --- 右上角关闭按钮 ---
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      size: 20,
                      color: Colors.grey,
                    ),
                    hoverColor: Colors.red.withValues(alpha: 0.1), // 悬停变淡红
                    splashRadius: 20,
                    tooltip: "关闭",
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// 抽取一个美观的选项组件
  Widget _buildDialogItem(
      BuildContext context, {
        required dynamic icon,
        required Color color,
        required String label,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: HugeIcon(icon: icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }


  // 构建列表主体
  Widget _buildRoomList(BuildContext context, WidgetRef ref) {
    final filteredRooms = ref.watch(filteredRoomListProvider);
    final query = ref.watch(roomSearchQueryProvider);
    if (filteredRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              query.isEmpty ? "暂无消息会话" : "未找到相关会话",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // 使用 RefreshIndicator 实现下拉刷新
    return RefreshIndicator(
      onRefresh: () => ref.read(roomListServiceProvider.notifier).refresh(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        child: ListView.builder(
          itemCount: filteredRooms.length,
          itemBuilder: (context, index) {
            return _RoomItem(room: filteredRooms[index]);
          },
        ),
      ),
    );
  }
}

// 抽离单个会话项，提高性能
class _RoomItem extends ConsumerWidget {
  final ChatRoomVO room;

  const _RoomItem({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeId = ref.watch(activeRoomIdProvider);
    final isSelected = activeId == room.roomId;
    final isSingle = room.roomType == 0;

    // 如果是单聊 (roomType == 0)，我们去联系人服务里找对方的在线状态
    bool isOnline = false;
    if (isSingle && room.peerId != null) {
      isOnline = ref.watch(
        contactListServiceProvider.select((asyncMap) {
          final contact = asyncMap.value?[room.peerId];
          return contact?.onlineStatus ?? false;
        }),
      );
    }

    return ListTile(
      visualDensity: VisualDensity.compact,
      dense: true,
      onTap: () {
        ref.read(activeRoomIdProvider.notifier).setActive(room.roomId!);
      },
      selected: isSelected,
      selectedTileColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.3),

      // 左侧头像
      leading: AvatarWidget(
        url: room.roomAvatar,
        name: room.roomName,
        status: isSingle
            ? (isOnline ? AvatarStatus.online : AvatarStatus.offline)
            : AvatarStatus.none,
      ),
      // 中间名称和最后消息
      title: Text(
        room.roomName ?? "未知会话",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        room.lastMessage?.content ?? "",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateUtil.formatTime(room.lastMessage?.timestamp),
            style: TextStyle(fontSize: 12),
          ),
          // 未读消息数徽章
          VibratingBadge(messageCount: room.unreadCount ?? 0),
        ],
      ),
    );
  }
}
