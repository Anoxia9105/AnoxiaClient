import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/features/chat/presentation/widgets/room_list_dialog_menus.dart';
import 'package:anoxia/features/chat/presentation/widgets/room_list_item.dart';
import 'package:anoxia/features/chat/presentation/widgets/skeleton/chat_room_list_skeleton.dart';
import 'package:anoxia/framework/domain/ChatRoomVO.dart';
import 'package:anoxia/framework/provider/chat/room/pinned_rooms_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:hugeicons/hugeicons.dart';

/// 聊天房间列表页面
///
/// 展示所有聊天会话，支持：
/// - 搜索过滤
/// - 置顶/取消置顶
/// - 标记已读
/// - 删除/解散房间
/// - 下拉刷新
class ChatRoomList extends ConsumerStatefulWidget {
  const ChatRoomList({super.key});

  @override
  ConsumerState createState() => _ChatRoomListState();
}

class _ChatRoomListState extends ConsumerState<ChatRoomList> {
  /// 搜索框控制器
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        leading: () {
          /// 如果是移动端 显示菜单按钮 打开个人中心抽屉
          if (DeviceUtil.isRealMobile()) {
            return IconButton(
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedMenuTwoLine),
              onPressed: () => ZoomDrawer.of(context)?.toggle(),
            );
          }
        }(),
        title: () {
          /// 如果是桌面 显示搜索框
          if (DeviceUtil.isRealDesktop()) {
            return Row(
              children: [
                Expanded(
                  child: SizedBox(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => ref
                          .read(roomSearchQueryProvider.notifier)
                          .update(val),
                      maxLength: 20,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        counterText: '',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        // 有搜索内容时显示清除按钮
                        suffixIcon:
                            ref.watch(roomSearchQueryProvider).isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.cancel, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(roomSearchQueryProvider.notifier)
                                      .update('');
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'chat_search_placeholder'.tr(),
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
                // 添加房间/好友按钮
                Builder(
                  builder: (context) {
                    return IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedLayerAdd,
                        size: 20,
                      ),
                      onPressed: () =>
                          RoomListDialogMenus.showTopRightDialog(context),
                    );
                  },
                ),
              ],
            );
          }

          /// 移动端显示标题
          return Text('sidebar_chat'.tr());
        }(),
        actions: [
          if (DeviceUtil.isRealMobile()) ...[
            // 添加房间/好友按钮
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedLayerAdd,
                    size: 20,
                  ),
                  onPressed: () =>
                      RoomListDialogMenus.showTopRightDialog(context),
                );
              },
            ),
          ],
        ],
      ),
      // 异步状态处理
      body: _buildRoomList(context, ref),
    );
  }

  /// 构建房间列表
  Widget _buildRoomList(BuildContext context, WidgetRef ref) {
    /// 获取过滤后的房间列表、搜索查询和置顶房间 ID 列表
    final filteredRooms = ref.watch(filteredRoomListProvider);

    /// 搜索查询和置顶房间 ID 列表用于空状态提示和排序逻辑
    final query = ref.watch(roomSearchQueryProvider);

    /// 置顶房间 ID 列表用于将置顶房间排在前面
    final pinnedIds = ref.watch(pinnedRoomsProvider);

    if (filteredRooms == null) {
      return const ChatRoomListSkeleton();
    }

    /// 如果没有任何房间，显示空状态提示
    if (filteredRooms.isEmpty) {
      return RefreshIndicator(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        color: Theme.of(context).colorScheme.primary,
        onRefresh: () => ref.read(roomListServiceProvider.notifier).refresh(),

        /// 使用 CustomScrollView + SliverFillRemaining 实现下拉刷新和空状态提示的兼容
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedComment01,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      query.isEmpty
                          ? 'chat_no_conversations'.tr()
                          : 'chat_no_related_conversations'.tr(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final pinned = <ChatRoomVO>[];
    final normal = <ChatRoomVO>[];
    for (final r in filteredRooms) {
      final id = r.roomId;
      if (id != null && pinnedIds.contains(id)) {
        pinned.add(r);
      } else {
        normal.add(r);
      }
    }
    final sortedRooms = <ChatRoomVO>[...pinned, ...normal];

    /// 下拉刷新，调用 RoomListService 的 refresh 方法重新加载房间列表
    return RefreshIndicator(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () => ref.read(roomListServiceProvider.notifier).refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: sortedRooms.length,
        itemBuilder: (context, index) {
          return RoomListItem(id: sortedRooms[index].roomId ?? '');
        },
        clipBehavior: Clip.hardEdge,
      ),
    );
  }
}
