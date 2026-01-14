import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../common/utils/DateUtil.dart';
import '../../../common/widgets/AvatarWidget.dart';
import '../../../common/widgets/VibratingBadge.dart';
import '../../../framework/domain/ChatRoomVO.dart';
import '../../../framework/services/room_list_service.dart';

class ChatRoomList extends ConsumerWidget {
  const ChatRoomList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 监听房间列表状态
    final roomListAsync = ref.watch(roomListServiceProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: '搜索会话...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {},
            ),
          ],
        ),
      ),
      // 2. 使用 AsyncValue 的 when 模式处理不同状态
      body: roomListAsync.when(
        data: (rooms) => _buildRoomList(context, ref, rooms),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('加载失败')),
      ),
    );
  }

  // 构建列表主体
  Widget _buildRoomList(
    BuildContext context,
    WidgetRef ref,
    List<ChatRoomVO> rooms,
  ) {
    if (rooms.isEmpty) {
      return const Center(
        child: Text("暂无消息会话", style: TextStyle(color: Colors.grey)),
      );
    }

    // 使用 RefreshIndicator 实现下拉刷新
    return RefreshIndicator(
      onRefresh: () => ref.read(roomListServiceProvider.notifier).refresh(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        child: ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return _RoomItem(room: room);
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
  Widget build(BuildContext context,WidgetRef ref) {

    final activeId = ref.watch(activeRoomIdProvider);
    final isSelected = activeId == room.roomId;
    return ListTile(
      visualDensity: VisualDensity.compact,
      dense: true,
      onTap: () {

        ref.read(activeRoomIdProvider.notifier).setActive(room.roomId!);
      },
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),

      // 左侧头像
      leading: AvatarWidget(url: room.roomAvatar, name: room.roomName),
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
