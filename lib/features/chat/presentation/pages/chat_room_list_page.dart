import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/features/chat/presentation/widgets/room_list_dialog_menus.dart';
import 'package:anoxia/features/chat/presentation/widgets/room_list_item.dart';
import 'package:anoxia/features/chat/presentation/widgets/skeleton/chat_room_list_skeleton.dart';
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
    /// 获取过滤并排序后的异步房间列表
    final filteredRooms = ref.watch(filteredSortedRoomListAsyncProvider);

    /// 搜索查询用于空状态提示文案
    final query = ref.watch(roomSearchQueryProvider);

    return filteredRooms.when(
      loading: () => const ChatRoomListSkeleton(),
      error: (error, _) => _buildErrorState(context, ref, error),
      data: (rooms) {
        if (rooms.isEmpty) {
          return _buildEmptyState(context, ref, query);
        }

        /// 下拉刷新，调用 RoomListService 的 refresh 方法重新加载房间列表
        return RefreshIndicator(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          color: Theme.of(context).colorScheme.primary,
          onRefresh: () => ref.read(roomListServiceProvider.notifier).refresh(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              return RoomListItem(id: rooms[index].roomId ?? '');
            },
            clipBehavior: Clip.hardEdge,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, String query) {
    return RefreshIndicator(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () => ref.read(roomListServiceProvider.notifier).refresh(),
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

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return RefreshIndicator(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () => ref.read(roomListServiceProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'chat_load_failed'.tr(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () =>
                          ref.read(roomListServiceProvider.notifier).refresh(),
                      child: Text('update_retry_download'.tr()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
